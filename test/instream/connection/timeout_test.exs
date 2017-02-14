defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.InetsConnection


  test "timeout" do
    timeout = 10
    opts    = [
      database: "timeout",
      timeout:  timeout
    ]

    try do
      InetsConnection.query("", opts)

      flunk "did not receive expected timeout"
    catch
      :exit, reason ->
        assert { :timeout, { GenServer, :call, [ _, _, ^timeout ]}} = reason
    end
  end
end
