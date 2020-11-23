defmodule Instream.Connection.QueryPlanner do
  @moduledoc false

  alias Instream.Connection.QueryRunner
  alias Instream.Data.Read
  alias Instream.Query

  @doc """
  Executes a query.
  """
  @spec execute(Query.t() | String.t(), Keyword.t(), module) :: any
  def execute(%Query{type: :write} = query, opts, conn) do
    default_pool_timeout = conn.config([:pool_timeout]) || 5000

    pool_name = Module.concat(conn, Pool)
    pool_timeout = opts[:pool_timeout] || default_pool_timeout

    worker = :poolboy.checkout(pool_name, pool_timeout)

    result =
      if opts[:async] do
        GenServer.cast(worker, {:execute, query, opts})
      else
        GenServer.call(worker, {:execute, query, opts}, :infinity)
      end

    :ok = :poolboy.checkin(pool_name, worker)

    result
  end

  def execute(%Query{type: :ping} = query, opts, conn),
    do: QueryRunner.ping(query, opts, conn)

  def execute(%Query{type: :read} = query, opts, conn),
    do: QueryRunner.read(query, opts, conn)

  def execute(%Query{type: :status} = query, opts, conn),
    do: QueryRunner.status(query, opts, conn)

  def execute(%Query{type: :version} = query, opts, conn),
    do: QueryRunner.version(query, opts, conn)

  def execute(query, opts, conn) when is_binary(query) do
    query
    |> Read.query(opts)
    |> execute(opts, conn)
  end
end
