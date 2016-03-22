defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  alias Instream.Query.Builder

  alias Instream.TestHelpers.Connection
  alias Instream.TestHelpers.ConnectionWithOpts
  alias Instream.TestHelpers.GuestConnection
  alias Instream.TestHelpers.UnreachableConnection


  @database "test_database"
  @tags     %{ foo: "foo", bar: "bar" }


  defmodule TestSeries do
    use Instream.Series

    series do
      database    "test_database"
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :value
    end
  end


  test "ping connection" do
    assert :pong  == Connection.ping()
    assert :error == UnreachableConnection.ping()
    assert :error == ConnectionWithOpts.ping()
  end

  test "status connection" do
    assert :ok    == Connection.status()
    assert :error == UnreachableConnection.status()
    assert :error == ConnectionWithOpts.ping()
  end


  test "read from empty measurement" do
    result =
         Builder.from("empty_measurement")
      |> Builder.select("value")
      |> Connection.query(database: @database)

    assert %{ results: _ } = result
  end

  test "read using database in query string" do
    query_in  = "SELECT value FROM \"#{ @database }\".\"default\".\"empty_measurement\""
    query_out = "SELECT value FROM empty_measurement"

    result_in  = query_in  |> Connection.query()
    result_out = query_out |> Connection.query(database: @database)

    assert result_in == result_out
  end


  test "write data" do
    measurement = "write_data"
    data        = %{
      database: @database,
      points: [
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{ value: 0.66 }
        }
      ]
    }

    assert :ok == data |> Connection.write()

    # wait to ensure data was written
    :timer.sleep(250)

    # check data
    query  = "SELECT * FROM #{ measurement } GROUP BY *"
    result = query |> Connection.query(database: @database)

    %{ results: [%{ series: [%{ tags: values_tags,
                                values: value_rows }]}]} = result

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  test "write data async" do
    measurement = "write_data_async"
    data        = %{
      database: @database,
      points: [
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{ value: 0.99 }
        }
      ]
    }

    assert :ok == data |> Connection.write(async: true)

    # wait to ensure data was written
    :timer.sleep(250)

    # check data
    query  = "SELECT * FROM #{ measurement } GROUP BY *"
    result = query |> Connection.query(database: @database)

    %{ results: [%{ series: [%{ tags: values_tags,
                                values: value_rows }]}]} = result

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end


  test "writing series struct" do
    data = %TestSeries{}
    data = %{ data | fields: %{ data.fields | value: 17 }}
    data = %{ data | tags:   %{ data.tags   | foo: "foo", bar: "bar" }}

    assert :ok == data |> Connection.write()

    # wait to ensure data was written
    :timer.sleep(250)

    # check data
    query  = "SELECT * FROM data_write_struct GROUP BY *"
    result = query |> Connection.query(database: @database)

    %{ results: [%{ series: [%{ tags: values_tags,
                                values: value_rows }]}]} = result

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end


  test "write data with missing privileges" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: "write_data_privileges",
          fields: %{ value: 0.66 }
        }
      ]
    }

    %{ error: error } = data |> GuestConnection.write()

    assert String.contains?(error, "not authorized")
  end
end
