defmodule Instream.InfluxDBv2.Series.HydratorTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  alias Instream.TestHelpers.TestConnection

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "hydrator_test"

      tag :hydrator

      field :value, default: 100
    end
  end

  test "Flux query" do
    :ok =
      %{hydrator: "flux"}
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      """
        from(bucket:"#{TestConnection.config(:bucket)}")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "#{TestSeries.__meta__(:measurement)}" and
          r.hydrator == "flux"
        )
        |> last()
      """
      |> TestConnection.query()
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

  test "Flux query (pivoted)" do
    :ok =
      %{hydrator: "flux-pivoted"}
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      """
        from(bucket:"#{TestConnection.config(:bucket)}")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "#{TestSeries.__meta__(:measurement)}" and
          r.hydrator == "flux-pivoted"
        )
        |> last()
        |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
      """
      |> TestConnection.query()
      |> TestSeries.from_result()

    assert [
             %TestSeries{
               fields: %TestSeries.Fields{
                 value: 100
               },
               tags: %TestSeries.Tags{
                 hydrator: "flux-pivoted"
               },
               timestamp: timestamp
             }
           ] = result

    assert 0 < timestamp
  end

  test "InfluxQL query" do
    :ok =
      %{hydrator: "influxql"}
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      """
        SELECT LAST(value)
        FROM #{TestSeries.__meta__(:measurement)}
        WHERE hydrator='influxql'
        GROUP BY hydrator
      """
      |> TestConnection.query(query_language: :influxql)
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
end
