defmodule Instream.Connection.SupervisorTest do
  use ExUnit.Case, async: true

  defmodule Initializer do
    use Agent

    def start_link(_), do: Agent.start_link(fn -> nil end, name: __MODULE__)

    def call_init(conn), do: Agent.update(__MODULE__, fn _ -> conn end)
    def get_init, do: Agent.get(__MODULE__, & &1)
  end

  defmodule InitializerConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {Instream.Connection.SupervisorTest.Initializer, :call_init}
      ]
  end

  test "init function called upon connection (re-) start" do
    {:ok, _} = start_supervised(Initializer)
    {:ok, _} = start_supervised(InitializerConnection)

    assert InitializerConnection = Initializer.get_init()
  end
end
