defmodule Instream.Connection.QueryPlanner do
  @moduledoc false

  alias Instream.Data.Read
  alias Instream.Encoder.InfluxQL
  alias Instream.Query
  alias Instream.Query.Builder

  @doc """
  Executes a query.
  """
  @spec execute(Builder.t() | Query.t() | String.t(), Keyword.t(), module) :: any
  def execute(%Builder{} = query, opts, conn) do
    default_timeout = conn.config([:query_timeout])

    opts =
      opts
      |> Keyword.put(:method, opts[:method] || query.arguments[:method])
      |> Keyword.put(:timeout, opts[:timeout] || default_timeout)

    query
    |> InfluxQL.encode()
    |> Read.query(opts)
    |> execute(opts, conn)
  end

  def execute(%Query{} = query, opts, conn) do
    case opts[:async] do
      true -> execute_async(query, opts, conn)
      _ -> execute_sync(query, opts, conn)
    end
  end

  def execute(query, opts, conn) when is_binary(query) do
    query
    |> Read.query(opts)
    |> execute(opts, conn)
  end

  # Internal methods

  defp execute_async(query, opts, conn) do
    default_pool_timeout = conn.config([:pool_timeout]) || 5000
    pool_timeout = opts[:pool_timeout] || default_pool_timeout

    worker = :poolboy.checkout(conn.__pool__, pool_timeout)
    :ok = GenServer.cast(worker, {:execute, query, opts})
    :ok = :poolboy.checkin(conn.__pool__, worker)

    :ok
  end

  defp execute_sync(query, opts, conn) do
    default_pool_timeout = conn.config([:pool_timeout]) || 5000
    pool_timeout = opts[:pool_timeout] || default_pool_timeout

    worker = :poolboy.checkout(conn.__pool__, pool_timeout)
    result = GenServer.call(worker, {:execute, query, opts}, :infinity)
    :ok = :poolboy.checkin(conn.__pool__, worker)

    result
  end
end
