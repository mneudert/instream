defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  use Instream.Writer

  alias Instream.Encoder.Line, as: Encoder


  def write(query, _opts, conn) do
    payload = query.payload |> to_line()

    :ok = :gen_udp.send(
      conn[:udp_socket],
      conn[:hosts] |> hd() |> to_char_list(),
      conn[:port_udp],
      to_char_list(payload)
    )

    { 200, [], "" }  # always ":ok"
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> Encoder.encode()
end
