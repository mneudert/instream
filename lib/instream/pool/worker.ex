defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

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
end
