defmodule Instream.Connection.QueryRunner do
  @moduledoc false

  alias Instream.Connection.JSON
  alias Instream.Log.Metadata
  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry
  alias Instream.Query
  alias Instream.Query.Headers
  alias Instream.Query.URL
  alias Instream.Response

  @doc """
  Executes `:ping` queries.
  """
  @spec ping(Query.t(), Keyword.t(), map) :: :pong | :error
  def ping(%Query{} = query, opts, %{module: conn}) do
    config = conn.config()
    headers = Headers.assemble(config)

    {query_time, response} =
      :timer.tc(fn ->
        config
        |> URL.ping(query.opts[:host])
        |> :hackney.head(headers, "", http_opts(config, opts))
      end)

    result = Response.parse_ping(response)

    status =
      case response do
        {:ok, status, _} -> status
        _ -> 0
      end

    if false != opts[:log] do
      conn.__log__(%PingEntry{
        host: query.opts[:host] || config[:host],
        result: result,
        metadata: %Metadata{
          query_time: query_time,
          response_status: status
        }
      })
    end

    result
  end

  @doc """
  Executes `:read` queries.
  """
  @spec read(Query.t(), Keyword.t(), map) :: any
  def read(%Query{} = query, opts, %{module: conn}) do
    config = conn.config()
    json_decoder = JSON.decoder(conn)
    json_encoder = JSON.encoder(conn)
    opts = Keyword.put(opts, :json_decoder, json_decoder)
    opts = Keyword.put(opts, :json_encoder, json_encoder)

    headers = Headers.assemble(config, opts)

    body = read_body(query, opts)
    method = read_method(query, opts)
    url = read_url(config, query, opts)

    {query_time, response} =
      :timer.tc(fn ->
        :hackney.request(method, url, headers, body, http_opts(config, opts))
      end)

    case response do
      {:error, _} ->
        response

      {:ok, status, headers, client} ->
        {:ok, body} = :hackney.body(client)

        result = Response.maybe_parse({status, headers, body}, opts)

        if false != opts[:log] do
          conn.__log__(%QueryEntry{
            query: query.payload,
            metadata: %Metadata{
              query_time: query_time,
              response_status: status
            }
          })
        end

        result
    end
  end

  @doc """
  Execute `:status` queries.
  """
  @spec status(Query.t(), Keyword.t(), map) :: :ok | :error
  def status(%Query{} = query, opts, %{module: conn}) do
    config = conn.config()
    headers = Headers.assemble(config)

    {query_time, response} =
      :timer.tc(fn ->
        config
        |> URL.status(query.opts[:host])
        |> :hackney.head(headers, "", http_opts(config, opts))
      end)

    result = Response.parse_status(response)

    status =
      case response do
        {:ok, status, _} -> status
        _ -> 0
      end

    if false != opts[:log] do
      conn.__log__(%StatusEntry{
        host: query.opts[:host] || config[:host],
        result: result,
        metadata: %Metadata{
          query_time: query_time,
          response_status: status
        }
      })
    end

    result
  end

  @doc """
  Executes `:version` queries.
  """
  @spec version(Query.t(), Keyword.t(), map) :: any
  def version(%Query{} = query, opts, %{module: conn}) do
    config = conn.config()
    headers = Headers.assemble(config)

    config
    |> URL.ping(query.opts[:host])
    |> :hackney.head(headers, "", http_opts(config, opts))
    |> Response.parse_version()
  end

  @doc """
  Executes `:write` queries.
  """
  @spec write(Query.t(), Keyword.t(), map) :: any
  def write(%Query{} = query, opts, %{module: conn} = state) do
    config = conn.config()
    json_decoder = JSON.decoder(conn)
    opts = Keyword.put(opts, :json_decoder, json_decoder)

    {query_time, result} =
      :timer.tc(fn ->
        query
        |> config[:writer].write(opts, state)
        |> Response.maybe_parse(opts)
      end)

    if false != opts[:log] do
      conn.__log__(%WriteEntry{
        points: length(query.payload[:points]),
        metadata: %Metadata{
          query_time: query_time,
          response_status: 0
        }
      })
    end

    result
  end

  defp http_opts(config, opts) do
    call_opts = Keyword.get(opts, :http_opts, [])
    config_opts = Keyword.get(config, :http_opts, [])

    special_opts =
      case opts[:timeout] do
        nil -> []
        timeout -> [recv_timeout: timeout]
      end

    special_opts
    |> Keyword.merge(config_opts)
    |> Keyword.merge(call_opts)
  end

  defp read_body(query, opts) do
    case opts[:query_language] do
      :flux -> query.payload
      _ -> ""
    end
  end

  defp read_method(query, opts) do
    case opts[:query_language] do
      :flux -> :post
      _ -> query.method || opts[:method] || :get
    end
  end

  defp read_url(config, query, opts) do
    url =
      config
      |> URL.query(opts[:query_language])
      |> URL.append_database(opts[:database] || config[:database])
      |> URL.append_epoch(query.opts[:precision])

    url =
      case opts[:params] do
        params when is_map(params) ->
          {json_mod, json_fun, json_extra_args} = opts[:json_encoder]

          json_params = apply(json_mod, json_fun, [params | json_extra_args])

          URL.append_json_params(url, json_params)

        _ ->
          url
      end

    case opts[:query_language] do
      :flux -> url
      _ -> URL.append_query(url, query.payload)
    end
  end
end
