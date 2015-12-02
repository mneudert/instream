defmodule Instream.Connection.QueryPlanner do
  @moduledoc """
  Query planning coordinating the execution of all queries.
  """

  alias Instream.Query

  @doc """
  Executes a query.
  """
  @spec execute(Query.t, Keyword.t, module) :: any
  def execute(%Query{} = query, opts, conn) do
    case opts[:async] do
      true -> execute_async(query, opts, conn)
      _    -> execute_sync(query, opts, conn)
    end
  end


  # Internal methods

  defp execute_async(query, opts, conn) do
    :poolboy.transaction(
      conn.__pool__,
      &GenServer.cast(&1, { :execute, query, opts })
    )

    :ok
  end

  defp execute_sync(query, opts, conn) do
    :poolboy.transaction(
      conn.__pool__,
      &GenServer.call(&1, { :execute, query, opts })
    )
  end
end
