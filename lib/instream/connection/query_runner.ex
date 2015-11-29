defmodule Instream.Connection.QueryRunner do
  @moduledoc """
  Executes a query for a connection.
  """

  alias Instream.Query
  alias Instream.Query.Headers
  alias Instream.Query.URL
  alias Instream.Response


  @doc """
  Executes `:cluster` queries.
  """
  @spec cluster(Query.t, Keyword.t, Keyword.t) :: any
  def cluster(%Query{ payload: payload }, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
         conn
      |> URL.query()
      |> URL.append_query(payload)

    { :ok, status, headers, client } = :hackney.get(url, headers)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response } |> Response.maybe_parse(opts)
  end

  @doc """
  Execute `:ping` queries.
  """
  @spec ping(Keyword.t) :: :pong | :error
  def ping(conn) do
    headers = conn |> Headers.assemble()

    conn
    |> URL.ping()
    |> :hackney.head(headers)
    |> Response.parse_ping()
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

    { :ok, status, headers, client } = :hackney.get(url, headers)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response } |> Response.maybe_parse(opts)
  end

  @doc """
  Executes `:write` queries.
  """
  @spec write(Query.t, Keyword.t, Keyword.t) :: any
  def write(%Query{} = query, opts, conn) do
    query
    |> conn[:writer].write(opts, conn)
    |> Response.maybe_parse(opts)
  end
end
