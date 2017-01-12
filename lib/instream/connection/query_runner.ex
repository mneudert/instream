defmodule Instream.Connection.QueryRunner do
  @moduledoc """
  Executes a query for a connection.
  """

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
  @spec ping(Query.t, Keyword.t, map) :: :pong | :error
  def ping(%Query{} = query, opts, %{ module: conn }) do
    config  = conn.config()
    headers = Headers.assemble(config)

    { query_time, response } = :timer.tc fn ->
      config
      |> URL.ping(query.opts[:host])
      |> :hackney.head(headers, "", http_opts(config, opts))
    end

    result = Response.parse_ping(response)
    status = case response do
      { :ok, status, _ } -> status
      _                  -> 0
    end

    if false != opts[:log] do
      conn.__log__(%PingEntry{
        host:     query.opts[:host] || config[:host],
        result:   result,
        metadata: %Metadata{
          query_time:      query_time,
          response_status: status
        }
      })
    end

    result
  end

  @doc """
  Executes `:read` queries.
  """
  @spec read(Query.t, Keyword.t, map) :: any
  def read(%Query{} = query, opts, %{ module: conn }) do
    config  = conn.config()
    headers = Headers.assemble(config, opts)
    url     =
      config
      |> URL.query()
      |> URL.append_database(opts[:database] || config[:database])
      |> URL.append_epoch(query.opts[:precision])
      |> URL.append_query(query.payload)

    { query_time, { :ok, status, headers, client }} = :timer.tc fn ->
      (query.method || opts[:method] || :get)
      |> :hackney.request(url, headers, "", http_opts(config, opts))
    end

    { :ok, response } = :hackney.body(client)
    result            =
      { status, headers, response }
      |> Response.maybe_parse(opts)

    if false != opts[:log] do
      conn.__log__(%QueryEntry{
        query:    query.payload,
        metadata: %Metadata{
          query_time:      query_time,
          response_status: status
        }
      })
    end

    result
  end

  @doc """
  Execute `:status` queries.
  """
  @spec status(Query.t, Keyword.t, map) :: :ok | :error
  def status(%Query{} = query, opts, %{ module: conn }) do
    config  = conn.config()
    headers = Headers.assemble(config)

    { query_time, response } = :timer.tc fn ->
      config
      |> URL.status(query.opts[:host])
      |> :hackney.head(headers, "", http_opts(config, opts))
    end

    result = Response.parse_status(response)
    status = case response do
      { :ok, status, _ } -> status
      _                  -> 0
    end

    if false != opts[:log] do
      conn.__log__(%StatusEntry{
        host:     query.opts[:host] || config[:host],
        result:   result,
        metadata: %Metadata{
          query_time:      query_time,
          response_status: status
        }
      })
    end

    result
  end

  @doc """
  Executes `:version` queries.
  """
  @spec version(Query.t, Keyword.t, map) :: any
  def version(%Query{} = query, opts, %{ module: conn }) do
    config  = conn.config()
    headers = Headers.assemble(config)

    config
    |> URL.ping(query.opts[:host])
    |> :hackney.head(headers, "", http_opts(config, opts))
    |> Response.parse_version()
  end

  @doc """
  Executes `:write` queries.
  """
  @spec write(Query.t, Keyword.t, map) :: any
  def write(%Query{} = query, opts, %{ module: conn } = state) do
    config = conn.config()

    { query_time, result } = :timer.tc fn ->
      query
      |> config[:writer].write(opts, state)
      |> Response.maybe_parse(opts)
    end

    if false != opts[:log] do
      conn.__log__(%WriteEntry{
        points:   length(query.payload[:points]),
        metadata: %Metadata{
          query_time:      query_time,
          response_status: 0
        }
      })
    end

    result
  end


  defp http_opts(config, opts) do
    http_opts = Keyword.get(config, :http_opts, [])

    case opts[:timeout] do
      nil     -> http_opts
      timeout -> Keyword.put(http_opts, :recv_timeout, timeout)
    end
  end
end
