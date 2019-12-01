defmodule Instream.Pool.Worker do
  @moduledoc false

  use GenServer

  alias Instream.Connection.QueryRunner
  alias Instream.Query

  @behaviour :poolboy_worker

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(module: conn) do
    state = %{module: conn}

    case conn.config([:writer]) do
      Instream.Writer.UDP -> {:ok, connect_udp(state)}
      _ -> {:ok, state}
    end
  end

  def handle_call({:execute, %Query{type: :write} = query, opts}, _from, state) do
    reply = QueryRunner.write(query, opts, state)

    {:reply, reply, state}
  end

  def handle_cast({:execute, %Query{type: :write} = query, opts}, state) do
    _ = QueryRunner.write(query, opts, state)

    {:noreply, state}
  end

  def terminate(_reason, state) do
    case Map.get(state, :udp_socket) do
      nil -> :ok
      socket -> :gen_udp.close(socket)
    end
  end

  defp connect_udp(state) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])

    Map.put(state, :udp_socket, socket)
  end
end
