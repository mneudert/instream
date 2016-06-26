defmodule Instream.Connection.QueryPlanner do
  @moduledoc """
  Query planning coordinating the execution of all queries.
  """

  alias Instream.Data.Read
  alias Instream.Encoder.InfluxQL
  alias Instream.Query
  alias Instream.Query.Builder

  @doc """
  Executes a query.
  """
  @spec execute(Builder.t | Query.t | String.t, Keyword.t, module) :: any
  def execute(%Builder{} = query, opts, conn) do
    opts =
      opts
      |> Keyword.put(:method, opts[:method] || query.arguments[:method])

    query
    |> InfluxQL.encode()
    |> Read.query(opts)
    |> execute(opts, conn)
  end

  def execute(%Query{} = query, opts, conn) do
    case opts[:async] do
      true -> execute_async(query, opts, conn)
      _    -> execute_sync(query, opts, conn)
    end
  end

  def execute(query, opts, conn) when is_binary(query) do
    query
    |> Read.query(opts)
    |> execute(opts, conn)
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
      &GenServer.call(&1, { :execute, query, opts }, conn.config[:timeout])
    )
  end
end
