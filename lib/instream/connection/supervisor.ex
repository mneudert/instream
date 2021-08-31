defmodule Instream.Connection.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link(conn), do: Supervisor.start_link(__MODULE__, conn, name: conn)

  @impl Supervisor
  def init(conn) do
    :ok =
      case conn.config(:init) do
        nil -> :ok
        {mod, fun} -> apply(mod, fun, [conn])
        {mod, fun, extra_args} -> apply(mod, fun, [conn | extra_args])
      end

    writer = conn.config(:writer)

    workers =
      if Code.ensure_loaded?(writer) and function_exported?(writer, :writer_workers, 1) do
        writer.writer_workers(conn)
      else
        []
      end

    Supervisor.init(workers, strategy: :one_for_one)
  end
end
