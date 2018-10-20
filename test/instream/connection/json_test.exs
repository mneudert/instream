defmodule Instream.Connection.JSONTest do
  use ExUnit.Case, async: true

  defmodule JSONConnection do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: {JSONLibrary, :decode!, [[keys: :atoms]]},
        loggers: []
      ]
  end

  defmodule JSONModuleConnection do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: JSONLibrary,
        loggers: []
      ]
  end

  defmodule JSONLibrary do
    alias Instream.Connection.JSONTest.JSONLogger

    def decode!(data) do
      JSONLogger.log({:decode, data})
      Poison.decode!(data, keys: :atoms)
    end

    def decode!(data, options) do
      JSONLogger.log({:decode_mfa, data})
      Poison.decode!(data, options)
    end
  end

  defmodule JSONLogger do
    def start_link(), do: Agent.start_link(fn -> [] end, name: __MODULE__)

    def log(action), do: Agent.update(__MODULE__, fn actions -> [action | actions] end)
    def get(), do: Agent.get(__MODULE__, & &1)
  end

  test "json runtime configuration" do
    {:ok, _} = JSONLogger.start_link()
    {:ok, _} = Supervisor.start_link([JSONConnection], strategy: :one_for_one)
    {:ok, _} = Supervisor.start_link([JSONModuleConnection], strategy: :one_for_one)

    _ = JSONConnection.query("")
    _ = JSONModuleConnection.query("")

    assert [{:decode, _}, {:decode_mfa, _}] = JSONLogger.get()
  end
end
