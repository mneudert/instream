defmodule Instream.Data.ReadTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connection

  @database    "test_database"
  @measurement "empty_measurement"


  test "read from empty measurement" do
    query  = "SELECT value FROM #{ @measurement }"
    result = query |> Connection.query(database: @database)

    assert %{ results: _ } = result
  end

  test "database in query string" do
    query_in  = "SELECT value FROM \"#{ @database }\".\"default\".\"#{ @measurement }\""
    query_out = "SELECT value FROM #{ @measurement }"

    result_in  = query_in  |> Connection.query()
    result_out = query_out |> Connection.query(database: @database)

    assert result_in == result_out
  end
end
