defmodule Instream.Connection.WriterTest do
  use ExUnit.Case, async: true

  defmodule WriterConnection do
    alias Instream.Connection.WriterTest.TestWriter

    use Instream.Connection,
      otp_app: :instream,
      config: [
        auth: [username: "instream_test", password: "instream_test"],
        loggers: [],
        writer: TestWriter
      ]
  end

  defmodule WriterSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "custom_connection_writer"

      field :binary
    end
  end

  defmodule TestWriter do
    alias Instream.Writer.Line

    @behaviour Instream.Writer

    def write(payload, opts, worker_state) do
      payload
      |> Line.write(opts, worker_state)
      |> maybe_modify_error()
    end

    defp maybe_modify_error({400, headers, body} = response) do
      case Jason.decode!(body) do
        %{"error" => _} -> {400, headers, Jason.encode!(%{"error" => "error has changed!"})}
        _ -> response
      end
    end

    defp maybe_modify_error(response), do: response
  end

  test "json runtime configuration" do
    {:ok, _} = start_supervised(WriterConnection)

    :ok =
      %{binary: "binary"}
      |> WriterSeries.from_map()
      |> WriterConnection.write()

    %{error: error} =
      %{binary: 12_345}
      |> WriterSeries.from_map()
      |> WriterConnection.write()

    assert "error has changed!" == error
  end
end
