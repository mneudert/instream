defmodule Instream.Connection.QueryPlanner do
  @moduledoc false

  alias Instream.Connection.QueryRunner
  alias Instream.Data.Read
  alias Instream.Query

  @doc """
  Executes a query.
  """
  @spec execute(Query.t() | String.t(), Keyword.t(), module) :: any
  def execute(%Query{type: :write} = query, opts, conn), do: QueryRunner.write(query, opts, conn)

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
