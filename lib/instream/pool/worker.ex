defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

  alias Instream.Query

  @behaviour :poolboy_worker

  @doc """
  Starts the worker process.
  """
  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  @doc """
  Initializes the worker.
  """
  @spec init(Keyword.t) :: { :ok, Keyword.t }
  def init(conn), do: { :ok, conn }


  # GenServer callbacks

  @doc false
  def handle_call({ :execute, query, opts }, _from, conn) do
    { :reply, execute(query, opts, conn), conn }
  end

  @doc false
  def handle_cast({ :execute, query, opts }, conn) do
    execute(query, opts, conn)

    { :noreply, conn }
  end


  # Utility methods

  defp execute(%Query{ type: type } = query, opts, conn) do
    case type do
      :cluster -> Query.Cluster.execute(query, opts, conn)
      :read    -> Query.Read.execute(query, opts, conn)
      :write   -> Query.Write.execute(query, opts, conn)
    end
  end
end
