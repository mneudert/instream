defmodule Instream.Data.WriteTest do
  use ExUnit.Case, async: true

  alias Instream.Data.Read
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


  @database    "test_database"
  @measurement "data_write"
  @tags        %{ foo: "foo", bar: "bar" }


  test "write data" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: @measurement,
          tags: @tags,
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

    assert nil == result

    # wait to ensure data was written
    :timer.sleep(100)

    # check data
    query  = "SELECT * FROM data_write_struct" |> Read.query()
    result = query |> Connection.execute(database: @database)

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
          measurement: @measurement,
          fields: %{ value: 0.66 }
        }
      ]
    }

    %{ error: error } = data |> Write.query() |> GuestConnection.execute()

    assert String.contains?(error, "not authorized")
  end
end
