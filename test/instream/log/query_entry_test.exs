defmodule Instream.Log.QueryEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.TestHelpers.Connections.LogConnection

  test "logging read request" do
    query = "SELECT value FROM empty_measurement"

    log =
      capture_io(:user, fn ->
        _ = LogConnection.query(query)

        :timer.sleep(10)
      end)

    assert String.contains?(log, "query")
    assert String.contains?(log, query)

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=200")
  end
end
