defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection


  test "timeout" do
    timeout = 7
    opts    = [
      http_opts: [ pool: :instream_test_sleeper ],
      timeout:   timeout
    ]

    try do
      DefaultConnection.execute("", opts)

      flunk "did not receive expected timeout"
    catch
      :exit, reason ->
        assert { :timeout, { GenServer, :call, [ _, _, ^timeout ]}} = reason
    end
  end
end
