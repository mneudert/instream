defmodule Instream.Connection.JSONTest do
  use ExUnit.Case, async: true

  defmodule JSONConnectionModule do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: JSONLibrary,
        loggers: []
      ]
  end

  defmodule JSONConnectionPartial do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: {JSONLibrary, :decode_partial},
        loggers: []
      ]
  end

  defmodule JSONConnectionFull do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: {JSONLibrary, :decode_full, [[keys: :atoms]]},
        loggers: []
      ]
  end

  defmodule JSONLibrary do
    alias Instream.Connection.JSONTest.JSONLogger

    def decode!(data) do
      JSONLogger.log(:decode_module)
      Jason.decode!(data, keys: :atoms)
    end

    def decode_partial(data) do
      JSONLogger.log(:decode_partial)
      Jason.decode!(data, keys: :atoms)
    end

    def decode_full(data, keys: :atoms) do
      JSONLogger.log(:decode_full)
      Jason.decode!(data, keys: :atoms)
    end
  end

  defmodule JSONLogger do
    use Agent

    def start_link(_), do: Agent.start_link(fn -> [] end, name: __MODULE__)

    def log(action), do: Agent.update(__MODULE__, fn actions -> [action | actions] end)
    def flush, do: Agent.get_and_update(__MODULE__, &{&1, []})
  end

  test "json runtime configuration" do
    {:ok, _} = start_supervised(JSONLogger)
    {:ok, _} = start_supervised(JSONConnectionFull)
    {:ok, _} = start_supervised(JSONConnectionModule)
    {:ok, _} = start_supervised(JSONConnectionPartial)

    _ = JSONConnectionModule.query("")
    _ = JSONConnectionPartial.query("")
    _ = JSONConnectionFull.query("")

    assert [:decode_full, :decode_partial, :decode_module] = JSONLogger.flush()
  end
end
