defmodule Instream.Log.StatusEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.TestHelpers.LogConnection


  test "logging status requests" do
    log = capture_io :user, fn ->
      :ok = LogConnection.status()

      :timer.sleep(10)
    end

    assert String.contains?(log, "status")
    assert String.contains?(log, "ok")

    assert String.contains?(log, hd(LogConnection.config[:hosts]))
  end
end
