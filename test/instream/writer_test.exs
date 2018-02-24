defmodule Instream.WriterTest do
  use ExUnit.Case, async: true

  import Instream.TestHelpers.Retry

  alias Instream.Admin.RetentionPolicy
  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.UDPConnection

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

  test "writer protocol: Line" do
    assert :ok ==
             %{
               timestamp: 1_439_587_926,
               proto: "Line",
               value: "Line"
             }
             |> ProtocolsSeries.from_map()
             |> DefaultConnection.write(precision: :second)

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='Line'",
                 database: ProtocolsSeries.__meta__(:database),
                 precision: :nanosecond
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [
                       %{
                         values: [[1_439_587_926_000_000_000, "Line", "Line"]]
                       }
                     ]
                   }
                 ]
               } ->
                 true

               _ ->
                 false
             end
           )
  end

  @tag :udp
  test "writer protocol: UDP" do
    assert :ok ==
             %{
               timestamp: 1_439_587_927_000_000_000,
               proto: "UDP",
               value: "UDP"
             }
             |> ProtocolsSeries.from_map()
             |> UDPConnection.write()

    assert retry(
             2500,
             50,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='UDP'",
                 database: ProtocolsSeries.__meta__(:database),
                 precision: :nanosecond
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [
                       %{
                         values: [[1_439_587_927_000_000_000, "UDP", "UDP"]]
                       }
                     ]
                   }
                 ]
               } ->
                 true

               _ ->
                 false
             end
           )
  end

  test "line protocol data encoding" do
    assert :ok ==
             %{
               binary: "binary",
               boolean: false,
               float: 1.1,
               integer: 100
             }
             |> LineEncodingSeries.from_map()
             |> DefaultConnection.write()

    assert retry(
             1000,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{LineEncodingSeries.__meta__(:measurement)} GROUP BY *",
                 database: LineEncodingSeries.__meta__(:database)
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [
                       %{
                         values: [[_, "binary", false, 1.1, 100]]
                       }
                     ]
                   }
                 ]
               } ->
                 true

               _ ->
                 false
             end
           )
  end

  test "protocol error decoding" do
    assert :ok ==
             %{binary: "binary"}
             |> ErrorsSeries.from_map()
             |> DefaultConnection.write()

    # wait to ensure data was written
    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{ErrorsSeries.__meta__(:measurement)}",
                 database: ErrorsSeries.__meta__(:database)
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [_]
                   }
                 ]
               } ->
                 true

               _ ->
                 false
             end
           )

    # make entry fail
    %{error: error} =
      %{binary: 12345}
      |> ErrorsSeries.from_map()
      |> DefaultConnection.write()

    String.contains?(error, "conflict")
  end

  test "line protocol batch series" do
    assert :ok ==
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

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{BatchSeries.__meta__(:measurement)}",
                 database: BatchSeries.__meta__(:database)
               )
             end,
             fn
               %{
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
               } ->
                 true

               _ ->
                 false
             end
           )
  end

  test "writing without all tags present" do
    assert :ok ==
             %{
               filled: "filled_tag",
               value: 100
             }
             |> EmptyTagSeries.from_map()
             |> DefaultConnection.write()

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{EmptyTagSeries.__meta__(:measurement)}",
                 database: EmptyTagSeries.__meta__(:database)
               )
             end,
             fn
               %{results: [%{series: [%{columns: columns}]}]} ->
                 Enum.member?(columns, "filled") && Enum.member?(columns, "defaulting") &&
                   Enum.member?(columns, "value") && !Enum.member?(columns, "empty")

               _ ->
                 false
             end
           )
  end

  test "writing with passed database option" do
    database = "test_database"

    assert :ok ==
             %{value: 100}
             |> CustomDatabaseSeries.from_map()
             |> DefaultConnection.write(database: database)

    assert retry(
             250,
             25,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{CustomDatabaseSeries.__meta__(:measurement)}",
                 database: database
               )
             end,
             fn
               %{results: [%{series: [%{columns: columns}]}]} -> Enum.member?(columns, "value")
               _ -> false
             end
           )
  end

  test "writing with passed retention policy option" do
    RetentionPolicy.create("one_week", "test_database", "1w", 1)
    |> DefaultConnection.execute()

    assert :ok ==
             %{proto: "ForRp", value: "Line"}
             |> ProtocolsSeries.from_map()
             |> DefaultConnection.write(retention_policy: "one_week")

    assert retry(
             250,
             25,
             fn ->
               [
                 DefaultConnection.query(
                   "SELECT * FROM writer_protocols WHERE proto='ForRp'",
                   database: "test_database"
                 ),
                 DefaultConnection.query(
                   ~s[SELECT * FROM "one_week"."writer_protocols" WHERE proto='ForRp'],
                   database: "test_database"
                 )
               ]
             end,
             fn
               [
                 %{results: [should_not_be_in_default_rp]},
                 %{results: [%{series: [%{values: [[_, "ForRp", "Line"]]}]}]}
               ] ->
                 !Map.has_key?(should_not_be_in_default_rp, :series)

               _ ->
                 false
             end
           )
  end
end
