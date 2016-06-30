defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connection


  test "timeout" do
    timeout = 1

    try do
      Connection.execute("SHOW FIELD KEYS", timeout: timeout)

      flunk("expected :exit not thrown (or query was faster than 1ms)!")
    catch
      :exit, reason ->
        assert { :timeout, { GenServer, :call, [ _, _, ^timeout ]}} = reason
    end

    # hide the fact that the internal GenServer
    # has a timeout induced MatchError
    :timer.sleep(250)
  end
end
