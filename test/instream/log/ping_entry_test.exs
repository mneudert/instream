defmodule Instream.Log.PingEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.TestHelpers.LogConnection


  test "logging ping requests" do
    log = capture_io :user, fn ->
      :pong = LogConnection.ping()

      :timer.sleep(10)
    end

    assert String.contains?(log, "ping")
    assert String.contains?(log, "pong")

    assert String.contains?(log, hd(LogConnection.config[:hosts]))
  end
end
