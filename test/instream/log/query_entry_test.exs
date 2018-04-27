defmodule Instream.Log.QueryEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Instream.TestHelpers.Connections.LogConnection

  test "logging read request" do
    query = "SELECT value FROM empty_measurement"

    log =
      capture_log(fn ->
        _ = LogConnection.query(query)

        :timer.sleep(10)
      end)

    assert String.contains?(log, "query")
    assert String.contains?(log, query)

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=200")
  end

  test "logging query with redacted password" do
    query = ~s(CREATE USER "instream_test" WITH PASSWORD "instream_test")

    log =
      capture_log(fn ->
        _ = LogConnection.query(query)

        :timer.sleep(10)
      end)

    assert String.contains?(log, "CREATE USER")
    refute String.contains?(log, ~s(PASSWORD "instream_test"))
  end
end
