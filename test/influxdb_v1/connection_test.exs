defmodule Instream.InfluxDBv1.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :value
    end
  end

  @tags %{foo: "foo", bar: "bar"}

  test "ping connection" do
    assert :pong = DefaultConnection.ping()
  end

  test "status connection" do
    assert :ok = DefaultConnection.status()
  end

  test "version connection" do
    assert is_binary(DefaultConnection.version())
  end

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

    query = "SELECT value FROM params WHERE foo = $foo_val"
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

  test "write data" do
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

  test "writing series struct" do
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
end
