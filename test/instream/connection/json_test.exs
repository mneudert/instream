defmodule Instream.Connection.JSONTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.JSON

  defmodule JSONConnectionModule do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      config: [
        json_decoder: JSONLibrary,
        json_encoder: JSONLibrary
      ]
  end

  defmodule JSONConnectionPartial do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      config: [
        json_decoder: {JSONLibrary, :decode_partial},
        json_encoder: {JSONLibrary, :encode_partial}
      ]
  end

  defmodule JSONConnectionFull do
    alias Instream.Connection.JSONTest.JSONLibrary

    use Instream.Connection,
      config: [
        json_decoder: {JSONLibrary, :decode_full, [[keys: :atoms]]},
        json_encoder: {JSONLibrary, :encode_full, [[foo: :bar]]}
      ]
  end

  defmodule JSONLibrary do
    def decode!(_), do: %{decode: :decode!}
    def decode_partial(_), do: %{decode: :decode_partial}
    def decode_full(_, keys: :atoms), do: %{decode: :decode_full}

    def encode!(_), do: "encode!"
    def encode_partial(_), do: "encode_partial"
    def encode_full(_, foo: :bar), do: "encode_full"
  end

  test "json runtime configuration" do
    assert %{decode: :decode!} = JSON.decode("test", JSONConnectionModule)
    assert %{decode: :decode_partial} = JSON.decode("test", JSONConnectionPartial)
    assert %{decode: :decode_full} = JSON.decode("test", JSONConnectionFull)

    assert "encode!" = JSON.encode(%{foo: :bar}, JSONConnectionModule)
    assert "encode_partial" = JSON.encode(%{foo: :bar}, JSONConnectionPartial)
    assert "encode_full" = JSON.encode(%{foo: :bar}, JSONConnectionFull)
  end
end
