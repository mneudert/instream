defmodule Instream.Connection.Supervisor do
  @moduledoc """
  Connection Supervisor.
  """

  use Supervisor

  alias Instream.Pool

  @doc """
  Starts the supervisor.
  """
  @spec start_link(atom) :: Supervisor.on_start()
  def start_link(conn) do
    Supervisor.start_link(__MODULE__, conn, name: Module.concat(conn, Supervisor))
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
