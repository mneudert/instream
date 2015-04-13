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
  def handle_call({ :execute, query, opts }, _from, conn) do
    { :reply, execute(query, opts, conn), conn }
  end


  # Utility methods

  defp execute(%Query{ type: type } = query, opts, conn) do
    case type do
      :host -> Query.Host.execute(query, opts, conn)
      :read -> Query.Read.execute(query, opts, conn)
    end
  end
end
