defmodule Instream.Connection.WriterTest do
  use ExUnit.Case, async: true

  defmodule WriterConnection do
    alias Instream.Connection.WriterTest.TestWriter

    use Instream.Connection,
      config: [
        loggers: [],
        writer: TestWriter
      ]
  end

  defmodule TestWriter do
    @behaviour Instream.Writer

    def write(%{payload: [%{response: response}]}, _, _), do: response
  end

  test "custom writer configuration" do
    assert :ok = WriterConnection.write(%{response: {:ok, 200, [], ""}})

    assert %{error: "custom writer"} =
             WriterConnection.write(%{response: {:ok, 500, [], "custom writer"}})
  end
end
