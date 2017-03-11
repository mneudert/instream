defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.InetsConnection


  test "timeout" do
    timeout = 10
    opts    = [
      database: "timeout",
      timeout:  timeout
    ]

    assert { :error, :timeout } == InetsConnection.query("", opts)
  end
end
