defmodule Instream.Connection.QueryRunnerV1 do
  @moduledoc false

  alias Instream.Connection.JSON
  alias Instream.Connection.ResponseParserV1
  alias Instream.Encoder.Line
  alias Instream.HTTPClient
  alias Instream.Log.Metadata
  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry
  alias Instream.Query.Headers
  alias Instream.Query.URL

  @doc """
  Executes `:ping` queries.
  """
  @spec ping(Keyword.t(), module) :: :pong | :error
  def ping(opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts)
    http_opts = http_opts(config, opts)
    url = URL.ping(config)

    {query_time, response} =
      :timer.tc(fn ->
        config[:http_client].request(:head, url, headers, "", http_opts)
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

      log(config[:loggers], %PingEntry{
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
  @spec read(String.t(), Keyword.t(), module) :: any
  def read(query, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts)
    http_opts = http_opts(config, opts)

    body = read_body(query, opts)
    method = read_method(opts)
    url = read_url(conn, query, opts)

    {query_time, response} =
      :timer.tc(fn ->
        config[:http_client].request(method, url, headers, body, http_opts)
      end)

    case response do
      {:ok, status, _, _} ->
        result = ResponseParserV1.maybe_parse(response, conn, opts)

        if false != opts[:log] do
          log(config[:loggers], %QueryEntry{
            query: query,
            result: result,
            metadata: %Metadata{
              query_time: query_time,
              response_status: status
            }
          })
        end

        result

      {:error, _} ->
        response
    end
  end

  @doc """
  Execute `:status` queries.
  """
  @spec status(Keyword.t(), module) :: :ok | :error
  def status(opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts)
    http_opts = http_opts(config, opts)
    url = URL.status(config)

    {query_time, response} =
      :timer.tc(fn ->
        config[:http_client].request(:head, url, headers, "", http_opts)
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

      log(config[:loggers], %StatusEntry{
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
  @spec version(Keyword.t(), module) :: any
  def version(opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts)
    http_opts = http_opts(config, opts)
    url = URL.ping(config)

    response = config[:http_client].request(:head, url, headers, "", http_opts)

    case response do
      {:ok, 204, headers} ->
        case HTTPClient.Headers.find("x-influxdb-version", headers) do
          nil -> "unknown"
          version -> version
        end

      _ ->
        :error
    end
  end

  @doc """
  Executes `:write` queries.
  """
  @spec write([Line.point()], Keyword.t(), module) :: any
  def write(points, opts, conn) do
    config = conn.config()

    {query_time, result} =
      :timer.tc(fn ->
        points
        |> config[:writer].write(opts, conn)
        |> ResponseParserV1.maybe_parse(conn, opts)
      end)

    if false != opts[:log] do
      log(config[:loggers], %WriteEntry{
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
    Keyword.merge(
      Keyword.get(config, :http_opts, []),
      Keyword.get(opts, :http_opts, [])
    )
  end

  defp log([_ | _] = loggers, entry) do
    Enum.each(loggers, fn {mod, fun, extra_args} ->
      apply(mod, fun, [entry | extra_args])
    end)
  end

  defp log(_, _), do: :ok

  defp read_body(query, opts) do
    case opts[:query_language] do
      :flux -> query
      _ -> ""
    end
  end

  defp read_method(opts) do
    case opts[:query_language] do
      :flux -> :post
      _ -> opts[:method] || :get
    end
  end

  defp read_url(conn, query, opts) do
    config = conn.config()
    url = URL.query(config, opts)

    case opts[:query_language] do
      :flux ->
        url

      _ ->
        case opts[:params] do
          params when is_map(params) ->
            params
            |> JSON.encode(conn)
            |> URL.append_json_params(url)

          _ ->
            url
        end
        |> URL.append_query(query)
    end
  end
end
