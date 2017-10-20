defmodule Instream.Log.PingEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.TestHelpers.Connections.LogConnection

  test "logging ping requests" do
    log =
      capture_io(:user, fn ->
        :pong = LogConnection.ping()

        :timer.sleep(10)
      end)

    assert String.contains?(log, "ping")
    assert String.contains?(log, "pong")

    assert String.contains?(log, LogConnection.config([:host]))

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=204")
  end
end
