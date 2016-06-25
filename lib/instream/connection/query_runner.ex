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
  @spec ping(Query.t, Keyword.t, Keyword.t) :: :pong | :error
  def ping(%Query{} = query, opts, conn) do
    headers = conn |> Headers.assemble()

    { query_time, response } = :timer.tc fn ->
      conn
      |> URL.ping(query.opts[:host])
      |> :hackney.head(headers, "", Keyword.get(conn, :http_opts, []))
    end

    result = response |> Response.parse_ping()
    status = case response do
      { :ok, status, _ } -> status
      _                  -> 0
    end

    if false != opts[:log] do
      conn[:module].__log__(%PingEntry{
        host:     query.opts[:host] || conn[:host],
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
  @spec read(Query.t, Keyword.t, Keyword.t) :: any
  def read(%Query{} = query, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
      conn
      |> URL.query()
      |> URL.append_database(opts[:database])
      |> URL.append_epoch(query.opts[:precision])
      |> URL.append_query(query.payload)

    http_opts = Keyword.get(conn, :http_opts, [])
    require Logger
    Logger.warn inspect conn
    Logger.warn inspect http_opts
    { query_time, { :ok, status, headers, client }} = :timer.tc fn ->
      (query.method || opts[:method] || :get)
      |> :hackney.request(url, headers, "", http_opts)
    end

    { :ok, response } = :hackney.body(client)
    result            =
      { status, headers, response }
      |> Response.maybe_parse(opts)

    if false != opts[:log] do
      conn[:module].__log__(%QueryEntry{
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
  @spec status(Query.t, Keyword.t, Keyword.t) :: :ok | :error
  def status(%Query{} = query, opts, conn) do
    headers = conn |> Headers.assemble()

    { query_time, response } = :timer.tc fn ->
      conn
      |> URL.status(query.opts[:host])
      |> :hackney.head(headers, "", Keyword.get(conn, :http_opts, []))
    end

    result = response |> Response.parse_status()
    status = case response do
      { :ok, status, _ } -> status
      _                  -> 0
    end

    if false != opts[:log] do
      conn[:module].__log__(%StatusEntry{
        host:     query.opts[:host] || conn[:host],
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
  Executes `:write` queries.
  """
  @spec write(Query.t, Keyword.t, Keyword.t) :: any
  def write(%Query{} = query, opts, conn) do
    { query_time, result } = :timer.tc fn ->
      query
      |> conn[:writer].write(opts, conn)
      |> Response.maybe_parse(opts)
    end

    if false != opts[:log] do
      conn[:module].__log__(%WriteEntry{
        points:   length(query.payload[:points]),
        metadata: %Metadata{
          query_time:      query_time,
          response_status: 0
        }
      })
    end

    result
  end
end
