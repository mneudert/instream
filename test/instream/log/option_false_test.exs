defmodule Instream.Log.OptionFalse do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.TestHelpers.Connections.LogConnection

  test "not logging ping requests" do
    assert "" ==
             capture_io(:user, fn ->
               :pong = LogConnection.ping(log: false)

               :timer.sleep(10)
             end)
  end

  test "logging read request" do
    assert "" ==
             capture_io(:user, fn ->
               query = "SELECT value FROM empty_measurement"
               _ = LogConnection.query(query, log: false)

               :timer.sleep(10)
             end)
  end
end
