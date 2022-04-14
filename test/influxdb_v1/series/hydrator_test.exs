defmodule Instream.InfluxDBv1.Series.HydratorTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"
  @moduletag :"influxdb_exclude_2.1"
  @moduletag :"influxdb_exclude_2.2"

  alias Instream.TestHelpers.TestConnection

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "hydrator_test"

      tag :hydrator

      field :value, default: 100
    end
  end

  test "InfluxQL query" do
    :ok =
      %{hydrator: "influxql"}
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      """
        SELECT *
        FROM #{TestSeries.__meta__(:measurement)}
        WHERE hydrator='influxql'
        ORDER BY time DESC
        LIMIT 1
      """
      |> TestConnection.query()
      |> TestSeries.from_result()

    assert [
             %TestSeries{
               fields: %TestSeries.Fields{
                 value: 100
               },
               tags: %TestSeries.Tags{
                 hydrator: "influxql"
               },
               timestamp: timestamp
             }
           ] = result

    assert 0 < timestamp
  end

  @tag :"influxdb_include_1.8"
  test "Flux query" do
    :ok =
      %{hydrator: "flux"}
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      """
        from(bucket:"test_database/autogen")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "#{TestSeries.__meta__(:measurement)}" and
          r.hydrator == "flux"
        )
        |> last()
      """
      |> TestConnection.query(query_language: :flux)
      |> TestSeries.from_result()

    assert [
             %TestSeries{
               fields: %TestSeries.Fields{
                 value: 100
               },
               tags: %TestSeries.Tags{
                 hydrator: "flux"
               },
               timestamp: timestamp
             }
           ] = result

    assert 0 < timestamp
  end
end
