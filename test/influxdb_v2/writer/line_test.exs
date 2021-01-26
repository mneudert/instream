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
            r._measurement == "#{ProtocolsSeries.__meta__(:measurement)}" and
            r.proto == "Line"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement,proto")
    assert String.contains?(result, "Line,value,#{ProtocolsSeries.__meta__(:measurement)},Line")
  end

  test "line protocol data encoding" do
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
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement")
    assert String.contains?(result, "binary,binary,#{LineEncodingSeries.__meta__(:measurement)}")
    assert String.contains?(result, "false,boolean,#{LineEncodingSeries.__meta__(:measurement)}")
    assert String.contains?(result, "1.1,float,#{LineEncodingSeries.__meta__(:measurement)}")
    assert String.contains?(result, "100,integer,#{LineEncodingSeries.__meta__(:measurement)}")
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
            r._measurement == "#{BatchSeries.__meta__(:measurement)}"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement,scope")
    assert String.contains?(result, "1.23456,value,#{BatchSeries.__meta__(:measurement)},inside")
    assert String.contains?(result, "9.87654,value,#{BatchSeries.__meta__(:measurement)},outside")
  end

  test "writing without all tags present" do
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
            r._measurement == "#{EmptyTagSeries.__meta__(:measurement)}"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement,defaulting,filled")

    assert String.contains?(
             result,
             "100,value,#{EmptyTagSeries.__meta__(:measurement)},default_value,filled_tag"
           )
  end

  test "writing with passed org/bucket option" do
    org = DefaultConnection.config(:org)
    bucket = DefaultConnection.config(:bucket)

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
            r._measurement == "#{CustomOrgBucketSeries.__meta__(:measurement)}"
          )
        """,
        query_language: :flux
      )

    assert String.contains?(result, "_value,_field,_measurement")
    assert String.contains?(result, "100,value,#{CustomOrgBucketSeries.__meta__(:measurement)}")
  end
end
