defmodule Instream.Connection.Supervisor do
  @moduledoc false

  use Supervisor

  alias Instream.Pool.Worker

  @doc false
  def start_link(conn, name) do
    Supervisor.start_link(__MODULE__, conn, name: name)
  end

  @doc false
  def init(conn) do
    :ok =
      case conn.config([:init]) do
        nil -> :ok
        {mod, fun} -> apply(mod, fun, [conn])
      end

    Supervisor.init([pool_spec(conn)], strategy: :one_for_one)
  end

  defp pool_spec(conn) do
    pool_name = Module.concat(conn, Pool)

    pool_opts =
      (conn.config([:pool]) || [])
      |> Keyword.take([:size, :max_overflow])
      |> Keyword.put(:name, {:local, pool_name})
      |> Keyword.put(:worker_module, Worker)

    :poolboy.child_spec(conn, pool_opts, module: conn)
  end
end
