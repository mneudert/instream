defmodule Instream.InetsProxy.PingTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.InetsConnection

  test "ping connection" do
    assert :pong == InetsConnection.ping()
  end
end
