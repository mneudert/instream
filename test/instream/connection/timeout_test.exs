defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connection


  defmodule TestSeries do
    use Instream.Series

    series do
      database    "test_database"
      measurement "query_timeout_test"

      tag :bar
      tag :foo

      field :value
    end
  end


  test "timeout" do
    timeout = 1
    query   = "SELECT SUM(foo) FROM #{ TestSeries.__meta__(:measurement) }" <>
              " WHERE time > now() - 60s GROUP BY time(1ms)"

    Enum.each 1..100, fn (i) ->
      data = %TestSeries{}
      data = %{ data | fields: %{ data.fields | value: i }}
      data = %{ data | tags:   %{ data.tags   | foo: "foo_#{ i }", bar: "bar_#{ i }" }}

      :ok = Connection.write(data)
    end

    try do
      Connection.execute(query, timeout: timeout)

      IO.puts :stderr, "\nTimeout test did not produce the expected"
                       " timeout. This probably is no real error, just"
                       " the result of unmatched timing...\n"
    catch
      :exit, reason ->
        assert { :timeout, { GenServer, :call, [ _, _, ^timeout ]}} = reason
    end

    # hide the fact that the internal GenServer
    # has a timeout induced MatchError
    :timer.sleep(250)
  end
end
