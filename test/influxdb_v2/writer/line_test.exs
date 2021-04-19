defmodule Instream.InfluxDBv2.Writer.LineTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule BatchSeries do
    use Instream.Series

    series do
      measurement "location"

      tag :scope

      field :value
    end
  end

  defmodule EmptyTagSeries do
    use Instream.Series

    series do
      measurement "empty_tags"

      tag :filled
      tag :defaulting, default: "default_value"
      tag :empty

      field :value
    end
  end

  defmodule ErrorsSeries do
    use Instream.Series

    series do
      measurement "writer_errors"

      field :binary
    end
  end

  defmodule LineEncodingSeries do
    use Instream.Series

    series do
      measurement "writer_line_encoding"

      field :binary
      field :boolean
      field :float
      field :integer
    end
  end

  defmodule CustomOrgBucketSeries do
    use Instream.Series

    series do
      measurement "writer_org_bucket_option"

      field :value
    end
  end

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
      measurement "writer_protocols"

      tag :proto

      field :value
    end
  end

  test "writing no points alway succeeds" do
    assert :ok = DefaultConnection.write([])
  end

  test "writer protocol: Line" do
    measurement = ProtocolsSeries.__meta__(:measurement)
    timestamp = 1_439_587_926

    :ok =
      %{
        timestamp: timestamp,
        proto: "Line",
        value: "Line"
      }
      |> ProtocolsSeries.from_map()
      |> DefaultConnection.write(precision: :second)

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(
            start: #{timestamp - 30},
            stop: #{timestamp + 30}
          )
          |> filter(fn: (r) =>
            r._measurement == "#{measurement}" and
            r.proto == "Line"
          )
          |> first()
        """,
        query_language: :flux
      )

    assert [
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => "Line",
               "proto" => "Line",
               "result" => "_result"
             }
           ] = result
  end

  test "line protocol data encoding" do
    measurement = LineEncodingSeries.__meta__(:measurement)

    :ok =
      %{
        binary: "binary",
        boolean: false,
        float: 1.1,
        integer: 100
      }
      |> LineEncodingSeries.from_map()
      |> DefaultConnection.write()

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(start: -5m)
          |> filter(fn: (r) =>
            r._measurement == "#{LineEncodingSeries.__meta__(:measurement)}"
          )
          |> first()
        """,
        query_language: :flux
      )

    [
      [
        %{
          "_field" => "binary",
          "_measurement" => ^measurement,
          "_value" => "binary",
          "result" => "_result",
          "table" => 0
        }
      ],
      [
        %{
          "_field" => "boolean",
          "_measurement" => ^measurement,
          "_value" => "false",
          "result" => "_result",
          "table" => 1
        }
      ],
      [
        %{
          "_field" => "float",
          "_measurement" => ^measurement,
          "_value" => 1.1,
          "result" => "_result",
          "table" => 2
        }
      ],
      [
        %{
          "_field" => "integer",
          "_measurement" => ^measurement,
          "_value" => 100,
          "result" => "_result",
          "table" => 3
        }
      ]
    ] = result
  end

  test "protocol error decoding" do
    :ok =
      %{binary: "binary"}
      |> ErrorsSeries.from_map()
      |> DefaultConnection.write()

    # make entry fail
    %{code: _, message: error} =
      %{binary: 12_345}
      |> ErrorsSeries.from_map()
      |> DefaultConnection.write()

    assert String.contains?(error, "conflict")
  end

  test "line protocol batch series" do
    measurement = BatchSeries.__meta__(:measurement)
    timestamp = 1_439_587_926

    :ok =
      [
        %{
          timestamp: timestamp,
          scope: "inside",
          value: 1.23456
        },
        %{
          timestamp: timestamp + 1,
          scope: "outside",
          value: 9.87654
        }
      ]
      |> Enum.map(&BatchSeries.from_map/1)
      |> DefaultConnection.write(precision: :second)

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(
            start: #{timestamp - 30},
            stop: #{timestamp + 30}
          )
          |> filter(fn: (r) =>
            r._measurement == "#{measurement}"
          )
          |> first()
        """,
        query_language: :flux
      )

    assert [
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => 1.23456,
               "result" => "_result",
               "scope" => "inside"
             },
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => 9.87654,
               "result" => "_result",
               "scope" => "outside"
             }
           ] = result
  end

  test "writing without all tags present" do
    measurement = EmptyTagSeries.__meta__(:measurement)

    :ok =
      %{
        filled: "filled_tag",
        value: 100
      }
      |> EmptyTagSeries.from_map()
      |> DefaultConnection.write()

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(start: -5m)
          |> filter(fn: (r) =>
            r._measurement == "#{measurement}"
          )
          |> first()
        """,
        query_language: :flux
      )

    assert [
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => 100,
               "defaulting" => "default_value",
               "filled" => "filled_tag",
               "result" => "_result"
             }
           ] = result
  end

  test "writing with passed org/bucket option" do
    org = DefaultConnection.config(:org)
    bucket = DefaultConnection.config(:bucket)
    measurement = CustomOrgBucketSeries.__meta__(:measurement)

    :ok =
      %{value: 100}
      |> CustomOrgBucketSeries.from_map()
      |> DefaultConnection.write(org: org, bucket: bucket)

    result =
      DefaultConnection.query(
        """
          from(bucket: "#{DefaultConnection.config(:bucket)}")
          |> range(start: -5m)
          |> filter(fn: (r) =>
            r._measurement == "#{measurement}"
          )
          |> first()
        """,
        query_language: :flux
      )

    assert [
             %{
               "_field" => "value",
               "_measurement" => ^measurement,
               "_value" => 100,
               "result" => "_result"
             }
           ] = result
  end
end
