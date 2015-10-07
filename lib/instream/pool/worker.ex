defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

  use GenServer

  alias Instream.Query

  @behaviour :poolboy_worker

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  def init(conn), do: { :ok, conn }


  # GenServer callbacks

  def handle_call({ :execute, query, opts }, _from, conn) do
    { :reply, execute(query, opts, conn), conn }
  end

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
