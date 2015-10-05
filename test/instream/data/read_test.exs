defmodule Instream.Data.ReadTest do
  use ExUnit.Case, async: true

  alias Instream.Data.Read
  alias Instream.TestHelpers.Connection

  @database    "test_database"
  @measurement "empty_measurement"


  test "read from empty measurement" do
    query  = "SELECT value FROM #{ @measurement }" |> Read.query()
    result = query |> Connection.execute(database: @database)

    assert %{ results: _ } = result
  end

  test "database in query string" do
    query_in  = "SELECT value FROM \"#{ @database }\".\"default\".\"#{ @measurement }\"" |> Read.query()
    query_out = "SELECT value FROM #{ @measurement }" |> Read.query()

    result_in  = query_in  |> Connection.execute()
    result_out = query_out |> Connection.execute(database: @database)

    assert result_in == result_out
  end
end
