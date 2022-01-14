defmodule Instream.Connection.InitializerTest do
  use ExUnit.Case, async: true

  defmodule Initializer do
    use Agent

    def start_link(_), do: Agent.start_link(fn -> nil end, name: __MODULE__)

    def call_init(conn), do: Agent.update(__MODULE__, fn _ -> [conn] end)

    def call_init(conn, :extra, :args),
      do: Agent.update(__MODULE__, fn _ -> [conn, :extra, :args] end)

    def get_init, do: Agent.get(__MODULE__, & &1)
  end

  defmodule InitializerConnectionModFun do
    alias Instream.Connection.InitializerTest.Initializer

    use Instream.Connection,
      config: [
        init: {Initializer, :call_init}
      ]
  end

  defmodule InitializerConnectionModFunArgs do
    alias Instream.Connection.InitializerTest.Initializer

    use Instream.Connection,
      config: [
        init: {Initializer, :call_init, [:extra, :args]}
      ]
  end

  test "{mod, fun} initializer called upon connection (re-) start" do
    {:ok, _} = start_supervised(Initializer)
    {:ok, _} = start_supervised(InitializerConnectionModFun)

    assert [InitializerConnectionModFun] = Initializer.get_init()
  end

  test "{mod, fun, extra_args} initializer called upon connection (re-) start" do
    {:ok, _} = start_supervised(Initializer)
    {:ok, _} = start_supervised(InitializerConnectionModFunArgs)

    assert [InitializerConnectionModFunArgs, :extra, :args] = Initializer.get_init()
  end
end
