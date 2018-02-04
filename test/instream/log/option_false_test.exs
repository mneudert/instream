defmodule Instream.Log.OptionFalse do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Instream.TestHelpers.Connections.LogConnection

  test "not logging ping requests" do
    assert "" ==
             capture_log(fn ->
               :pong = LogConnection.ping(log: false)

               :timer.sleep(10)
             end)
  end

  test "logging read request" do
    assert "" ==
             capture_log(fn ->
               query = "SELECT value FROM empty_measurement"
               _ = LogConnection.query(query, log: false)

               :timer.sleep(10)
             end)
  end
end
