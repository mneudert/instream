defmodule Instream.Pool.Worker do
  @moduledoc """
  Pool worker.
  """

  use GenServer

  alias Instream.Connection.QueryRunner
  alias Instream.Query


  @behaviour :poolboy_worker

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn)
  end

  def init(conn) do
    case conn[:writer] do
      Instream.Writer.UDP -> { :ok, connect_udp(conn) }
      _                   -> { :ok, conn }
    end
  end

  def terminate(_reason, conn) do
    case conn[:udp_socket] do
      nil    -> :ok
      socket -> :gen_udp.close(socket)
    end
  end


  # GenServer callbacks

  def handle_call({ :execute, query, opts }, _from, conn) do
    { :reply, execute(query, opts, conn), conn }
  end

  def handle_cast({ :execute, query, opts }, conn) do
    execute(query, opts, conn)

    { :noreply, conn }
  end


  # Utility methods

  defp connect_udp(conn) do
    { :ok, socket } = :gen_udp.open(0, [ :binary, { :active, false }])

    conn
    |> Keyword.put_new(:udp_socket, socket)
  end

  defp execute(%Query{ type: type } = query, opts, conn) do
    case type do
      :ping  -> QueryRunner.ping(query, conn)
      :read  -> QueryRunner.read(query, opts, conn)
      :write -> QueryRunner.write(query, opts, conn)
    end
  end
end
