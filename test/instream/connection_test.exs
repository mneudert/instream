defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connection
  alias Instream.TestHelpers.UnreachableConnection


  test "ping connection" do
    assert :pong  == Connection.ping()
    assert :error == UnreachableConnection.ping()
  end
end
