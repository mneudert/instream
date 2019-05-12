defmodule Instream.Connection.JSONTest do
  use ExUnit.Case, async: true

  defmodule JSONConnectionModule do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: JSONLibrary,
        json_encoder: JSONLibrary,
        loggers: []
      ]
  end

  defmodule JSONConnectionPartial do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: {JSONLibrary, :decode_partial},
        json_encoder: {JSONLibrary, :encode_partial},
        loggers: []
      ]
  end

  defmodule JSONConnectionFull do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      otp_app: :instream,
      config: [
        json_decoder: {JSONLibrary, :decode_full, [[keys: :atoms]]},
        json_encoder: {JSONLibrary, :encode_full, [[foo: :bar]]},
        loggers: []
      ]
  end

  defmodule JSONLibrary do
    alias Instream.Connection.JSONTest.JSONLogger

    def decode!(data) do
      JSONLogger.log(:decode_module)
      Poison.decode!(data, keys: :atoms)
    end

    def decode_partial(data) do
      JSONLogger.log(:decode_partial)
      Poison.decode!(data, keys: :atoms)
    end

    def decode_full(data, keys: :atoms) do
      JSONLogger.log(:decode_full)
      Poison.decode!(data, keys: :atoms)
    end

    def encode!(data) do
      JSONLogger.log(:encode_module)
      Poison.encode!(data)
    end

    def encode_partial(data) do
      JSONLogger.log(:encode_partial)
      Poison.encode!(data)
    end

    def encode_full(data, foo: :bar) do
      JSONLogger.log(:encode_full)
      Poison.encode!(data)
    end
  end

  defmodule JSONLogger do
    def start_link, do: Agent.start_link(fn -> [] end, name: __MODULE__)

    def log(action), do: Agent.update(__MODULE__, fn actions -> [action | actions] end)
    def flush, do: Agent.get_and_update(__MODULE__, &{&1, []})
  end

  test "json runtime configuration" do
    connections = [JSONConnectionModule, JSONConnectionPartial, JSONConnectionFull]

    {:ok, _} = JSONLogger.start_link()
    {:ok, _} = Supervisor.start_link(connections, strategy: :one_for_one)

    _ = JSONConnectionModule.query("", params: %{})
    _ = JSONConnectionPartial.query("", params: %{})
    _ = JSONConnectionFull.query("", params: %{})

    assert [
             :decode_full,
             :encode_full,
             :decode_partial,
             :encode_partial,
             :decode_module,
             :encode_module
           ] = JSONLogger.flush()
  end
end
