defmodule Instream.Connection.Supervisor do
  @moduledoc false

  use Supervisor

  alias Instream.Pool

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

    Supervisor.init([Pool.Spec.spec(conn)], strategy: :one_for_one)
  end
end
