defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

  use GenServer

  alias Instream.Connection.QueryRunner
  alias Instream.Query

  @behaviour :poolboy_worker

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(%{module: conn} = default) do
    case conn.config([:writer]) do
      Instream.Writer.UDP -> {:ok, connect_udp(default)}
      _ -> {:ok, default}
    end
  end

  def terminate(_reason, state) do
    case Map.get(state, :udp_socket) do
      nil -> :ok
      socket -> :gen_udp.close(socket)
    end
  end

  # GenServer callbacks

  def handle_call({:execute, query, opts}, _from, state) do
    {:reply, execute(query, opts, state), state}
  end

  def handle_cast({:execute, query, opts}, state) do
    execute(query, opts, state)

    {:noreply, state}
  end

  # Utility methods

  defp connect_udp(state) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])

    Map.put(state, :udp_socket, socket)
  end

  defp execute(%Query{type: type} = query, opts, state) do
    case type do
      :ping -> QueryRunner.ping(query, opts, state)
      :read -> QueryRunner.read(query, opts, state)
      :status -> QueryRunner.status(query, opts, state)
      :version -> QueryRunner.version(query, opts, state)
      :write -> QueryRunner.write(query, opts, state)
    end
  end
end
