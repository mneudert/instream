defmodule Instream.Data.WriteTest do
  use ExUnit.Case, async: true

  alias Instream.Data.Write
  alias Instream.TestHelpers.Connection
  alias Instream.TestHelpers.GuestConnection


  defmodule TestSeries do
    use Instream.Series

    series do
      database    :test_database
      measurement :data_write_struct

      tag :bar
      tag :foo

      field :value
    end
  end


  @database "test_database"
  @tags     %{ foo: "foo", bar: "bar" }


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

    query  = data |> Write.query()
    result = query |> Connection.execute()

    assert :ok == result

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

    query  = data |> Write.query()
    result = query |> Connection.execute([ async: true ])

    assert :ok == result

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

    query  = data |> Write.query()
    result = query |> Connection.execute()

    assert :ok == result

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


  test "missing privileges" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: "write_data_privileges",
          fields: %{ value: 0.66 }
        }
      ]
    }

    %{ error: error } = data |> Write.query() |> GuestConnection.execute()

    assert String.contains?(error, "not authorized")
  end
end
