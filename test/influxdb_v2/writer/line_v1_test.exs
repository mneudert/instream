defmodule Instream.InfluxDBv2.Writer.LineV1Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  alias Instream.TestHelpers.TestConnection

  defmodule LineV1Connection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__, :init}
      ]

    def init(conn) do
      config =
        Keyword.merge(
          Application.get_env(:instream, TestConnection),
          writer: Instream.Writer.LineV1
        )

      Application.put_env(:instream, conn, config)
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

  test "writing no points always succeeds" do
    start_supervised!(LineV1Connection)

    assert :ok = LineV1Connection.write([])
  end

  test "writer protocol: Line" do
    start_supervised!(LineV1Connection)

    :ok =
      %{
        timestamp: 1_439_587_926,
        proto: "Line",
        value: "Line"
      }
      |> ProtocolsSeries.from_map()
      |> LineV1Connection.write(precision: :second)

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
             LineV1Connection.query(
               "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='Line'",
               precision: :nanosecond,
               query_language: :influxql
             )
  end

  test "writing with passed database option" do
    start_supervised!(LineV1Connection)

    database = LineV1Connection.config(:database)

    :ok =
      %{value: 100}
      |> CustomDatabaseSeries.from_map()
      |> LineV1Connection.write(database: database)

    assert %{results: [%{series: [%{columns: ["time", "value"], values: [_ | _]}]}]} =
             LineV1Connection.query(
               "SELECT * FROM #{CustomDatabaseSeries.__meta__(:measurement)}",
               query_language: :influxql
             )
  end
end
