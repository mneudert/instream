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
    data = %ProtocolsSeries{}
    data = %{data | fields: %{data.fields | value: "Line"}}
    data = %{data | tags: %{data.tags | proto: "Line"}}
    data = %{data | timestamp: 1_439_587_926}

    assert :ok == data |> DefaultConnection.write(precision: :second)

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
    data = %ProtocolsSeries{}
    data = %{data | fields: %{data.fields | value: "UDP"}}
    data = %{data | tags: %{data.tags | proto: "UDP"}}
    data = %{data | timestamp: 1_439_587_927_000_000_000}

    assert :ok == data |> UDPConnection.write()

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
    data = %LineEncodingSeries{}

    data = %{
      data
      | fields: %{
          data.fields
          | binary: "binary",
            boolean: false,
            float: 1.1,
            integer: 100
        }
    }

    assert :ok == data |> DefaultConnection.write()

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
    data = %ErrorsSeries{}
    data = %{data | fields: %{data.fields | binary: "binary"}}

    assert :ok == data |> DefaultConnection.write()

    # wait to ensure data was written
    :timer.sleep(250)

    # make entry fail
    data = %{data | fields: %{data.fields | binary: 12345}}

    # Line protocol write error
    %{error: error} = data |> DefaultConnection.write()

    String.contains?(error, "conflict")
  end

  test "line protocol batch series" do
    inside = %BatchSeries{}
    inside = %{inside | tags: %{inside.tags | scope: "inside"}}

    inside = %{inside | fields: %{inside.fields | value: 1.23456}}
    inside = %{inside | timestamp: 1_439_587_926}

    outside = %BatchSeries{}
    outside = %{outside | tags: %{outside.tags | scope: "outside"}}

    outside = %{outside | fields: %{outside.fields | value: 9.87654}}
    outside = %{outside | timestamp: 1_439_587_927}

    assert :ok == [inside, outside] |> DefaultConnection.write(precision: :second)

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
    entry = %EmptyTagSeries{}
    entry = %{entry | tags: %{entry.tags | filled: "filled_tag"}}
    entry = %{entry | fields: %{entry.fields | value: 100}}

    assert :ok = DefaultConnection.write(entry)

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

    entry = %CustomDatabaseSeries{}
    entry = %{entry | fields: %{entry.fields | value: 100}}

    assert :ok = DefaultConnection.write(entry, database: database)

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

    data = %ProtocolsSeries{}
    data = %{data | fields: %{data.fields | value: "Line"}}
    data = %{data | tags: %{data.tags | proto: "ForRp"}}

    assert :ok == data |> DefaultConnection.write(retention_policy: "one_week")

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
