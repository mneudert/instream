defmodule Instream.Log.DefaultLoggerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Log.DefaultLogger
  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry


  test "ping log entry" do
    entry = %PingEntry{ result: :test_ok }

    log = capture_io :user, fn ->
      DefaultLogger.log(entry)

      :timer.sleep(10)
    end

    assert String.contains?(log, to_string(entry.result))
  end

  test "query log entry" do
    entry = %QueryEntry{ query: "SELECT * FROM log_test" }

    log = capture_io :user, fn ->
      DefaultLogger.log(entry)

      :timer.sleep(10)
    end

    assert String.contains?(log, entry.query)
  end

  test "status log entry" do
    entry = %StatusEntry{ result: :test_ok }

    log = capture_io :user, fn ->
      DefaultLogger.log(entry)

      :timer.sleep(10)
    end

    assert String.contains?(log, to_string(entry.result))
  end

  test "write log entry" do
    entry = %WriteEntry{ points: 16 }

    log = capture_io :user, fn ->
      DefaultLogger.log(entry)

      :timer.sleep(10)
    end

    assert String.contains?(log, "#{ entry.points } points")
  end
end
