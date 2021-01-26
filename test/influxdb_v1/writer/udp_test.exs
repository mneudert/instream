defmodule Instream.InfluxDBv1.Writer.UDPTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  @moduletag :"influxdb_exclude_2.0"
  @moduletag :udp

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

  test "writing no points alway succeeds" do
    start_supervised!(UDPConnection)

    assert :ok = UDPConnection.write([])
  end

  test "writer protocol: UDP (async: false)" do
    start_supervised!(UDPConnection)

    assert :ok =
             %{
               timestamp: 1_439_587_927_000_000_000,
               proto: "UDP-sync",
               value: "UDP"
             }
             |> ProtocolsSeries.from_map()
             |> UDPConnection.write()

    retry_call = fn ->
      DefaultConnection.query(
        "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='UDP-sync'",
        precision: :nanosecond
      )
    end

    retry_test = fn
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

    assert retry(2500, 50, retry_call, retry_test)
  end

  test "writer protocol: UDP (async: true)" do
    start_supervised!(UDPConnection)

    assert :ok =
             %{
               timestamp: 1_439_587_927_000_000_000,
               proto: "UDP-async",
               value: "UDP"
             }
             |> ProtocolsSeries.from_map()
             |> UDPConnection.write(async: true)

    retry_call = fn ->
      DefaultConnection.query(
        "SELECT * FROM #{ProtocolsSeries.__meta__(:measurement)} WHERE proto='UDP-async'",
        precision: :nanosecond
      )
    end

    retry_test = fn
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

    assert retry(2500, 50, retry_call, retry_test)
  end

  defp retry(0, _, _, _), do: false

  defp retry(timeout, delay, retry_call, retry_test) do
    case retry_test.(retry_call.()) do
      true ->
        true

      false ->
        :timer.sleep(delay)
        retry(timeout - delay, delay, retry_call, retry_test)
    end
  end
end
