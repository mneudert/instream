defmodule Instream.Writer.LineTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule BatchSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "location"

      tag :scope

      field :value
    end
  end

  defmodule EmptyTagSeries do
    use Instream.Series

    series do
      database "test_database"
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
      database "test_database"
      measurement "writer_errors"

      field :binary
    end
  end

  defmodule LineEncodingSeries do
    use Instream.Series

    series do
      database "test_database"
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
      database "invalid_test_database"
      measurement "writer_database_option"

      field :value
    end
  end

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "writer_protocols"

      tag :proto

      field :value
    end
  end

  test "writing no points alway succeeds" do
    assert :ok = DefaultConnection.write(%{points: []})
  end

  test "writer protocol: Line" do
    :ok =
      %{
        timestamp: 1_439_587_926,
        proto: "Line",
        value: "Line"
      }
      |> ProtocolsSeries.from_map()
      |> DefaultConnection.write(precision: :second)

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
               database: ProtocolsSeries.__meta__(:database),
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
      |> DefaultConnection.write()

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
               "SELECT * FROM #{LineEncodingSeries.__meta__(:measurement)} GROUP BY *",
               database: LineEncodingSeries.__meta__(:database)
             )
  end

  test "protocol error decoding" do
    :ok =
      %{binary: "binary"}
      |> ErrorsSeries.from_map()
      |> DefaultConnection.write()

    assert %{
             results: [
               %{
                 series: [_]
               }
             ]
           } =
             DefaultConnection.query(
               "SELECT * FROM #{ErrorsSeries.__meta__(:measurement)}",
               database: ErrorsSeries.__meta__(:database)
             )

    # make entry fail
    %{error: error} =
      %{binary: 12_345}
      |> ErrorsSeries.from_map()
      |> DefaultConnection.write()

    String.contains?(error, "conflict")
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
      |> DefaultConnection.write(precision: :second)

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
           } =
             DefaultConnection.query(
               "SELECT * FROM #{BatchSeries.__meta__(:measurement)}",
               database: BatchSeries.__meta__(:database)
             )
  end

  test "writing without all tags present" do
    :ok =
      %{
        filled: "filled_tag",
        value: 100
      }
      |> EmptyTagSeries.from_map()
      |> DefaultConnection.write()

    assert %{results: [%{series: [%{columns: columns}]}]} =
             DefaultConnection.query(
               "SELECT * FROM #{EmptyTagSeries.__meta__(:measurement)}",
               database: EmptyTagSeries.__meta__(:database)
             )

    assert Enum.member?(columns, "filled")
    assert Enum.member?(columns, "defaulting")
    assert Enum.member?(columns, "value")
    refute Enum.member?(columns, "empty")
  end

  test "writing with passed database option" do
    database = "test_database"

    :ok =
      %{value: 100}
      |> CustomDatabaseSeries.from_map()
      |> DefaultConnection.write(database: database)

    assert %{results: [%{series: [%{columns: columns}]}]} =
             DefaultConnection.query(
               "SELECT * FROM #{CustomDatabaseSeries.__meta__(:measurement)}",
               database: database
             )

    assert Enum.member?(columns, "value")
  end

  test "writing with passed retention policy option" do
    _ =
      DefaultConnection.execute(
        "CREATE RETENTION POLICY one_week ON test_database" <>
          " DURATION 1w REPLICATION 1"
      )

    :ok =
      %{proto: "ForRp", value: "Line"}
      |> ProtocolsSeries.from_map()
      |> DefaultConnection.write(retention_policy: "one_week")

    assert %{results: [%{series: [%{values: [[_, "ForRp", "Line"]]}]}]} =
             DefaultConnection.query(
               ~s[SELECT * FROM "one_week"."writer_protocols" WHERE proto='ForRp'],
               database: "test_database"
             )

    assert %{results: [should_not_be_in_default_rp]} =
             DefaultConnection.query(
               "SELECT * FROM writer_protocols WHERE proto='ForRp'",
               database: "test_database"
             )

    refute Map.has_key?(should_not_be_in_default_rp, :series)
  end
end
