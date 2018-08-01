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
    opts = [name: Module.concat(conn, Supervisor)]
    Supervisor.start_link(__MODULE__, conn, opts)
  end

  @doc false
  def init(conn) do
    supervise([Pool.Spec.spec(conn)], strategy: :one_for_one)
  end
end
