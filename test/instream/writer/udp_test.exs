defmodule Instream.WriterTest do
  use ExUnit.Case, async: true

  import Instream.TestHelpers.Retry

  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.UDPConnection

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "writer_protocols"

      tag :proto

      field :value
    end
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
end
