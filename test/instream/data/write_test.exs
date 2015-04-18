defmodule Instream.Data.WriteTest do
  use ExUnit.Case, async: true

  alias Instream.Data.Read
  alias Instream.Data.Write
  alias Instream.TestHelpers.Connection

  @database    "test_database"
  @measurement "data_write"

  test "write data" do
    data = %{
      database: @database,
      points: [
        %{
          name:   @measurement,
          fields: %{ value: 0.66 }
        }
      ]
    }

    query  = data |> Write.query()
    result = query |> Connection.execute()

    assert nil == result

    # wait to ensure data was written
    :timer.sleep(100)

    # check data
    query  = "SELECT * FROM #{ @measurement }" |> Read.query()
    result = query |> Connection.execute(database: @database)

    %{ results: [%{ series: [%{ values: value_rows }]}]} = result

    assert 0 < length(value_rows)
  end
end
