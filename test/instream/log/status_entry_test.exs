defmodule Instream.Log.StatusEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  defmodule LogConnection do
    use Instream.Connection,
      config: [
        auth: [method: :query, username: "instream_test", password: "instream_test"]
      ]
  end

  setup do
    {:ok, _} = start_supervised(LogConnection)
    :ok
  end

  test "logging status requests" do
    log =
      capture_log(fn ->
        :ok = LogConnection.status()

        :timer.sleep(10)
      end)

    assert String.contains?(log, "status")
    assert String.contains?(log, "ok")

    assert String.contains?(log, LogConnection.config([:host]))

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=204")
  end
end
