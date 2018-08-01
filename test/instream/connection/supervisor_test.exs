defmodule Instream.Connection.SupervisorTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.InitConnection

  defmodule Initializer do
    def start_link, do: Agent.start_link(fn -> nil end, name: __MODULE__)

    def call_init(conn), do: Agent.update(__MODULE__, fn _ -> conn end)
    def get_init, do: Agent.get(__MODULE__, & &1)
  end

  setup do
    env = Application.get_env(:instream, InitConnection)

    :ok =
      Application.put_env(
        :instream,
        InitConnection,
        Keyword.put(env, :init, {Initializer, :call_init})
      )

    {:ok, _} = Initializer.start_link()

    on_exit(fn ->
      :ok = Application.put_env(:instream, InitConnection, env)
    end)
  end

  test "init function called upon connection (re-) start" do
    _ = Supervisor.start_link([InitConnection.child_spec()], strategy: :one_for_one)
    :ok = :timer.sleep(100)

    assert InitConnection == Initializer.get_init()
  end
end
