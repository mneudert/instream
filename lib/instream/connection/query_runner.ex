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
  @spec ping(Query.t(), Keyword.t(), module) :: :pong | :error
  def ping(%Query{}, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config)

    {query_time, response} =
      :timer.tc(fn ->
        config
        |> URL.ping()
        |> :hackney.head(headers, "", http_opts(config, opts))
      end)

    result =
      case response do
        {:ok, 204, _} -> :pong
        _ -> :error
      end

    if false != opts[:log] do
      status =
        case response do
          {:ok, status, _} -> status
          _ -> 0
        end

      conn.__log__(%PingEntry{
        host: config[:host],
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
  @spec read(Query.t(), Keyword.t(), module) :: any
  def read(%Query{payload: query_payload} = query, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts)

    body = read_body(query, opts)
    method = read_method(query, opts)
    url = read_url(conn, query, opts)

    {query_time, response} =
      :timer.tc(fn ->
        :hackney.request(method, url, headers, body, http_opts(config, opts))
      end)

    with {:ok, status, headers, client} <- response,
         {:ok, body} <- :hackney.body(client) do
      result = Response.maybe_parse({status, headers, body}, conn, opts)

      if false != opts[:log] do
        conn.__log__(%QueryEntry{
          query: query_payload,
          result: result,
          metadata: %Metadata{
            query_time: query_time,
            response_status: status
          }
        })
      end

      result
    else
      {:error, _} = error -> error
    end
  end

  @doc """
  Execute `:status` queries.
  """
  @spec status(Query.t(), Keyword.t(), module) :: :ok | :error
  def status(%Query{}, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config)

    {query_time, response} =
      :timer.tc(fn ->
        config
        |> URL.status()
        |> :hackney.head(headers, "", http_opts(config, opts))
      end)

    result =
      case response do
        {:ok, 204, _} -> :ok
        _ -> :error
      end

    if false != opts[:log] do
      status =
        case response do
          {:ok, status, _} -> status
          _ -> 0
        end

      conn.__log__(%StatusEntry{
        host: config[:host],
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
  @spec version(Query.t(), Keyword.t(), module) :: any
  def version(%Query{}, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config)

    response =
      config
      |> URL.ping()
      |> :hackney.head(headers, "", http_opts(config, opts))

    case response do
      {:ok, 204, headers} ->
        case List.keyfind(headers, "X-Influxdb-Version", 0) do
          {"X-Influxdb-Version", version} -> version
          _ -> "unknown"
        end

      _ ->
        :error
    end
  end

  @doc """
  Executes `:write` queries.
  """
  @spec write(Query.t(), Keyword.t(), map) :: any
  def write(%Query{payload: %{points: points}} = query, opts, %{module: conn} = state) do
    config = conn.config()

    {query_time, result} =
      :timer.tc(fn ->
        query
        |> config[:writer].write(opts, state)
        |> Response.maybe_parse(conn, opts)
      end)

    if false != opts[:log] do
      conn.__log__(%WriteEntry{
        points: length(points),
        result: result,
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

  defp read_body(%{payload: query_payload}, opts) do
    case opts[:query_language] do
      :flux -> query_payload
      _ -> ""
    end
  end

  defp read_method(%{method: query_method}, opts) do
    case opts[:query_language] do
      :flux -> :post
      _ -> query_method || opts[:method] || :get
    end
  end

  defp read_url(conn, %{opts: query_opts, payload: query_payload}, opts) do
    config = conn.config()

    url =
      config
      |> URL.query(opts[:query_language])
      |> URL.append_database(opts[:database] || config[:database])
      |> URL.append_epoch(query_opts[:precision])

    url =
      case opts[:params] do
        params when is_map(params) ->
          {json_mod, json_fun, json_extra_args} = JSON.encoder(conn)

          json_params = apply(json_mod, json_fun, [params | json_extra_args])

          URL.append_json_params(url, json_params)

        _ ->
          url
      end

    case opts[:query_language] do
      :flux -> url
      _ -> URL.append_query(url, query_payload)
    end
  end
end
