defmodule Instream.WriterTest do
  use ExUnit.Case, async: true

  import Instream.TestHelpers.Retry

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
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

  @tag :"influxdb_exclude_2.0"
  @tag :udp
  test "writing no points alway succeeds" do
    start_supervised(UDPConnection)

    assert :ok = UDPConnection.write([])
  end

  @tag :"influxdb_exclude_2.0"
  @tag :udp
  test "writer protocol: UDP (async: false)" do
    start_supervised(UDPConnection)

    assert :ok =
             %{
               timestamp: 1_439_587_927_000_000_000,
               proto: "UDP-sync",
               value: "UDP"
             }
             |> ProtocolsSeries.from_map()
             |> UDPConnection.write()

    assert retry(
             2500,
             50,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='UDP-sync'",
                 precision: :nanosecond
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [
                       %{
                         values: [[1_439_587_927_000_000_000, "UDP-sync", "UDP"]]
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

  @tag :"influxdb_exclude_2.0"
  @tag :udp
  test "writer protocol: UDP (async: true)" do
    start_supervised(UDPConnection)

    assert :ok =
             %{
               timestamp: 1_439_587_927_000_000_000,
               proto: "UDP-async",
               value: "UDP"
             }
             |> ProtocolsSeries.from_map()
             |> UDPConnection.write(async: true)

    assert retry(
             2500,
             50,
             fn ->
               DefaultConnection.query(
                 "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='UDP-async'",
                 precision: :nanosecond
               )
             end,
             fn
               %{
                 results: [
                   %{
                     series: [
                       %{
                         values: [[1_439_587_927_000_000_000, "UDP-async", "UDP"]]
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
