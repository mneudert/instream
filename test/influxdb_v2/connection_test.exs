defmodule Instream.InfluxDBv2.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

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

  test "mismatched InfluxDB version" do
    assert {:error, :version_mismatch} = DefaultConnection.ping()
    assert {:error, :version_mismatch} = DefaultConnection.status()
    assert {:error, :version_mismatch} = DefaultConnection.version()
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

    assert [
             %{
               "_field" => "value",
               "_measurement" => "write_data",
               "_value" => 0.66,
               "bar" => "bar",
               "foo" => "foo",
               "result" => "_result"
             }
             | _
           ] = result
  end

  test "writing series struct" do
    measurement = TestSeries.__meta__(:measurement)

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
            r._measurement == "#{measurement}"
          )
        """,
        query_language: :flux
      )

    assert [
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => 17,
               "bar" => "bar",
               "foo" => "foo",
               "result" => "_result"
             }
             | _
           ] = result
  end
end
