defmodule Instream.Writer.LineV2Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.DefaultConnectionV2

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

  defmodule CustomDatabaseSeries do
    use Instream.Series

    series do
      measurement "writer_database_option"

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
    assert :ok = DefaultConnectionV2.write([])
  end

  test "writer protocol: Line" do
    :ok =
      %{
        timestamp: 1_439_587_926,
        proto: "Line",
        value: "Line"
      }
      |> ProtocolsSeries.from_map()
      |> DefaultConnectionV2.write(precision: :second)

    assert %{
             results: [
               %{
                 series: [
                   %{
                     values: [[1_439_587_926_000_000_000, "Line", "Line"]]
                   }
                 ]
               }
             ]
           } =
             DefaultConnection.query(
               "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='Line'",
               precision: :nanosecond
             )
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
      |> DefaultConnectionV2.write()

    assert %{
             results: [
               %{
                 series: [
                   %{
                     values: [[_, "binary", false, 1.1, 100]]
                   }
                 ]
               }
             ]
           } =
             DefaultConnection.query(
               "SELECT * FROM #{LineEncodingSeries.__meta__(:measurement)} GROUP BY *"
             )
  end

  test "protocol error decoding" do
    :ok =
      %{binary: "binary"}
      |> ErrorsSeries.from_map()
      |> DefaultConnectionV2.write()

    assert %{
             results: [
               %{
                 series: [_]
               }
             ]
           } = DefaultConnection.query("SELECT * FROM #{ErrorsSeries.__meta__(:measurement)}")

    # make entry fail
    %{code: _, message: error} =
      %{binary: 12_345}
      |> ErrorsSeries.from_map()
      |> DefaultConnectionV2.write()

    assert String.contains?(error, "conflict")
  end

  test "line protocol batch series" do
    :ok =
      [
        %{
          timestamp: 1_439_587_926,
          scope: "inside",
          value: 1.23456
        },
        %{
          timestamp: 1_439_587_927,
          scope: "outside",
          value: 9.87654
        }
      ]
      |> Enum.map(&BatchSeries.from_map/1)
      |> DefaultConnectionV2.write(precision: :second)

    assert %{
             results: [
               %{
                 series: [
                   %{
                     columns: ["time", "scope", "value"],
                     values: [
                       ["2015-08-14T21:32:06Z", "inside", 1.23456],
                       ["2015-08-14T21:32:07Z", "outside", 9.87654]
                     ]
                   }
                 ]
               }
             ]
           } = DefaultConnection.query("SELECT * FROM #{BatchSeries.__meta__(:measurement)}")
  end

  test "writing without all tags present" do
    :ok =
      %{
        filled: "filled_tag",
        value: 100
      }
      |> EmptyTagSeries.from_map()
      |> DefaultConnectionV2.write()

    assert %{results: [%{series: [%{columns: columns}]}]} =
             DefaultConnection.query("SELECT * FROM #{EmptyTagSeries.__meta__(:measurement)}")

    assert Enum.member?(columns, "filled")
    assert Enum.member?(columns, "defaulting")
    assert Enum.member?(columns, "value")
    refute Enum.member?(columns, "empty")
  end

  test "writing with passed org/bucket option" do
    org = DefaultConnectionV2.config(:org)
    bucket = DefaultConnectionV2.config(:bucket)

    :ok =
      %{value: 100}
      |> CustomDatabaseSeries.from_map()
      |> DefaultConnectionV2.write(org: org, bucket: bucket)

    assert %{results: [%{series: [%{columns: columns}]}]} =
             DefaultConnection.query(
               "SELECT * FROM #{CustomDatabaseSeries.__meta__(:measurement)}"
             )

    assert Enum.member?(columns, "value")
  end
end
