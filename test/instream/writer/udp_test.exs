defmodule Instream.WriterTest do
  use ExUnit.Case, async: true

  import Instream.TestHelpers.Retry

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "writer_protocols"

      tag :proto

      field :value
    end
  end

  defmodule UDPConnection do
    use Instream.Connection,
      config: [
        loggers: [],
        port_udp: 8089,
        writer: Instream.Writer.UDP
      ]
  end

  @tag :udp
  test "writing no points alway succeeds" do
    start_supervised(UDPConnection)

    assert :ok = UDPConnection.write(%{points: []})
  end

  @tag :udp
  test "writer protocol: UDP" do
    start_supervised(UDPConnection)

    assert :ok =
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
end
