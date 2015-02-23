defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

  alias Instream.Query

  @behaviour :poolboy_worker

  @doc """
  Starts the worker process.
  """
  @spec start_link(conn :: Keyword.t) :: GenServer.on_start
  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  @doc """
  Initializes the worker.
  """
  @spec init(conn :: Keyword.t) :: { :ok, Keyword.t }
  def init(conn), do: { :ok, conn }


  # GenServer callbacks

  @doc false
  def handle_call({ :execute, query }, _from, conn) do
    { :reply, execute(query, conn), conn }
  end


  # Utility methods

  defp execute(%Query{ type: type } = query, conn) do
    case type do
      :query -> Query.Query.execute(query, conn)
    end
  end
end
