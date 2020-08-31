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
    writer = conn.config([:writer])

    state =
      if Code.ensure_loaded?(writer) and function_exported?(writer, :init_worker, 1) do
        writer.init_worker(%{module: conn})
      else
        %{module: conn}
      end

    {:ok, state}
  end

  def handle_call({:execute, %Query{type: :write} = query, opts}, _from, state) do
    reply = QueryRunner.write(query, opts, state)

    {:reply, reply, state}
  end

  def handle_cast({:execute, %Query{type: :write} = query, opts}, state) do
    _ = QueryRunner.write(query, opts, state)

    {:noreply, state}
  end

  def terminate(_reason, %{module: conn} = state) do
    writer = conn.config([:writer])

    if Code.ensure_loaded?(writer) and function_exported?(writer, :init_worker, 1) do
      writer.terminate_worker(state)
    else
      :ok
    end
  end
end
