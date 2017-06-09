defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: false

  alias Instream.TestHelpers.Connections.InetsConnection


  test "timeout" do
    timeout = 10
    opts    = [
      database: "timeout",
      timeout:  timeout
    ]

    assert { :error, :timeout } == InetsConnection.query("", opts)
  end

  test "timeout above GenServer defaults" do
    timeout = 7500
    opts    = [
      database: "timeout_long",
      timeout:  timeout
    ]

    assert { :error, :timeout } == InetsConnection.query("", opts)
  end
end
