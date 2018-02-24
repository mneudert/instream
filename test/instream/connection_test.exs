defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  import Instream.TestHelpers.Retry

  alias Instream.Query.Builder

  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.GuestConnection

  @database "test_database"
  @tags %{foo: "foo", bar: "bar"}

  defmodule TestSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :value
    end
  end

  test "ping connection" do
    assert :pong == DefaultConnection.ping()
  end

  test "status connection" do
    assert :ok == DefaultConnection.status()
  end

  test "version connection" do
    assert is_binary(DefaultConnection.version())
  end

  test "read from empty measurement" do
    result =
      Builder.from("empty_measurement")
      |> Builder.select("value")
      |> DefaultConnection.query(database: @database)

    assert %{results: _} = result
  end

  test "read using database in query string" do
    query_in = "SELECT value FROM \"#{@database}\".\"autogen\".\"empty_measurement\""
    query_out = "SELECT value FROM empty_measurement"

    result_in = query_in |> DefaultConnection.query()
    result_out = query_out |> DefaultConnection.query(database: @database)

    assert result_in == result_out
  end

  test "write data" do
    measurement = "write_data"

    assert :ok ==
             %{
               database: @database,
               points: [
                 %{
                   measurement: measurement,
                   tags: @tags,
                   fields: %{value: 0.66}
                 }
               ]
             }
             |> DefaultConnection.write()

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{measurement} GROUP BY *",
                 database: @database
               )
             end,
             fn
               %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} ->
                 assert @tags == values_tags
                 assert 0 < length(value_rows)

               _ ->
                 false
             end
           )
  end

  test "write data async" do
    measurement = "write_data_async"

    assert :ok ==
             %{
               database: @database,
               points: [
                 %{
                   measurement: measurement,
                   tags: @tags,
                   fields: %{value: 0.99}
                 }
               ]
             }
             |> DefaultConnection.write(async: true)

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{measurement} GROUP BY *",
                 database: @database
               )
             end,
             fn
               %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} ->
                 assert @tags == values_tags
                 assert 0 < length(value_rows)

               _ ->
                 false
             end
           )
  end

  test "writing series struct" do
    assert :ok ==
             %{
               bar: "bar",
               foo: "foo",
               value: 17
             }
             |> TestSeries.from_map()
             |> DefaultConnection.write()

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM data_write_struct GROUP BY *",
                 database: @database
               )
             end,
             fn
               %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} ->
                 assert @tags == values_tags
                 assert 0 < length(value_rows)

               _ ->
                 false
             end
           )
  end

  test "write data with missing privileges" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: "write_data_privileges",
          fields: %{value: 0.66}
        }
      ]
    }

    %{error: error} = data |> GuestConnection.write()

    assert String.contains?(error, "not authorized")
  end
end
