defmodule Instream.Connection.QueryRunnerV2 do
  @moduledoc false

  alias Instream.Connection.JSON
  alias Instream.Connection.ResponseParserV2
  alias Instream.Encoder.Line
  alias Instream.HTTPClient
  alias Instream.Log.DeleteEntry
  alias Instream.Log.Metadata
  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.WriteEntry
  alias Instream.Query.Headers
  alias Instream.Query.URL

  @doc """
  Executes `:delete` requests.
  """
  @spec delete(map(), Keyword.t(), module) :: any
  def delete(payload, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts) ++ [{"Content-Type", "application/json"}]
    http_opts = http_opts(config, opts)
    body = JSON.encode(payload, conn)
    url = URL.delete(config, opts)

    {query_time, response} =
      :timer.tc(fn ->
        config[:http_client].request(:post, url, headers, body, http_opts)
      end)

    result = ResponseParserV2.maybe_parse(response, conn, opts)

    if false != opts[:log] do
      status =
        case response do
          {:ok, status, _, _} -> status
          _ -> 0
        end

      log(config[:loggers], %DeleteEntry{
        payload: payload,
        result: result,
        metadata: %Metadata{
          query_time: query_time,
          response_status: status
        },
        conn: conn
      })
    end

    result
  end

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

    body = read_body(conn, query, opts)
    url = read_url(conn, query, opts)

    {query_time, response} =
      :timer.tc(fn ->
        config[:http_client].request(:post, url, headers, body, http_opts)
      end)

    case response do
      {:ok, status, _, _} ->
        result = ResponseParserV2.maybe_parse(response, conn, opts)

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
        |> ResponseParserV2.maybe_parse(conn, opts)
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

  defp read_body(conn, query, opts) do
    case opts[:query_language] do
      :influxql ->
        ""

      _ ->
        JSON.encode(
          %{
            type: "flux",
            query: query,
            dialect: %{
              annotations: ["datatype", "default", "group"]
            }
          },
          conn
        )
    end
  end

  defp read_url(conn, query, opts) do
    config = conn.config()
    url = URL.query(config, opts)

    case opts[:query_language] do
      :influxql ->
        case opts[:params] do
          params when is_map(params) ->
            params
            |> JSON.encode(conn)
            |> URL.append_json_params(url)

          _ ->
            url
        end
        |> URL.append_query(query)

      _ ->
        url
    end
  end
end
