defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  @database "test_database"
  @tags %{foo: "foo", bar: "bar"}

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :value
    end
  end

  test "read from empty measurement" do
    query = "SELECT value FROM empty_measurement"
    result = DefaultConnection.query(query)

    assert %{results: _} = result
  end

  test "read using database in query string" do
    query_in = "SELECT value FROM \"#{@database}\".\"autogen\".\"empty_measurement\""
    query_out = "SELECT value FROM empty_measurement"

    result_in = DefaultConnection.query(query_in)
    result_out = DefaultConnection.query(query_out)

    assert ^result_in = result_out
  end

  @tag :"influxdb_exclude_2.0"
  test "read using params" do
    test_field = ~S|string field value, only " need be quoted|
    test_tag = ~S|tag,value,with"commas"|

    :ok =
      DefaultConnection.write([
        %{
          measurement: "params",
          tags: %{foo: test_tag},
          fields: %{value: test_field}
        }
      ])

    query = "SELECT value FROM \"#{@database}\".\"autogen\".\"params\" WHERE foo = $foo_val"
    params = %{foo_val: test_tag}

    assert %{results: [%{series: [%{name: "params", values: [[_, ^test_field]]}]}]} =
             DefaultConnection.query(query, params: params)
  end

  @tag :"influxdb_include_1.8"
  test "read using flux query" do
    :ok =
      DefaultConnection.write([
        %{
          measurement: "flux",
          tags: %{foo: "bar"},
          fields: %{value: 1}
        }
      ])

    query = ~S[
      from(bucket:"test_database/autogen")
      |> range(start: -1h)
      |> filter(fn: (r) => r._measurement == "flux")
    ]

    result = DefaultConnection.query(query, query_language: :flux)

    assert "#datatype," <> _ = result

    assert String.contains?(result, "flux,bar")
    assert String.contains?(result, "_measurement,foo")
  end

  @tag :"influxdb_exclude_2.0"
  test "write data (v1)" do
    measurement = "write_data"

    :ok =
      DefaultConnection.write([
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{value: 0.66}
        }
      ])

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             DefaultConnection.query("SELECT * FROM #{measurement} GROUP BY *")

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  @tag :"influxdb_exclude_2.0"
  test "writing series struct (v1)" do
    :ok =
      %{
        bar: "bar",
        foo: "foo",
        value: 17
      }
      |> TestSeries.from_map()
      |> DefaultConnection.write()

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             DefaultConnection.query(
               "SELECT * FROM #{TestSeries.__meta__(:measurement)} GROUP BY *"
             )

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  @tag :"influxdb_include_2.0"
  test "write data (v2)" do
    measurement = "write_data"

    :ok =
      DefaultConnection.write([
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{value: 0.66}
        }
      ])

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(start: -5m)
          |> filter(fn: (r) =>
            r._measurement == "#{measurement}"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement,bar,foo")
    assert String.contains?(result, "0.66,value,#{measurement},bar,foo")
  end

  @tag :"influxdb_include_2.0"
  test "writing series struct (v2)" do
    :ok =
      %{
        bar: "bar",
        foo: "foo",
        value: 17
      }
      |> TestSeries.from_map()
      |> DefaultConnection.write()

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(start: -5m)
          |> filter(fn: (r) =>
            r._measurement == "#{TestSeries.__meta__(:measurement)}"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement,bar,foo")
    assert String.contains?(result, "17,value,#{TestSeries.__meta__(:measurement)},bar,foo")
  end
end
