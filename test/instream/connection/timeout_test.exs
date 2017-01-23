defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.TimeoutConnection


  test "timeout" do
    timeout = 7

    try do
      TimeoutConnection.execute("", [ timeout: timeout ])

      flunk "did not receive expected timeout"
    catch
      :exit, reason ->
        assert { :timeout, { GenServer, :call, [ _, _, ^timeout ]}} = reason
    end
  end
end
