defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  use Instream.Writer

  alias Instream.Encoder.Line, as: Encoder


  def write(query, _opts, %{ module: conn, udp_socket: udp_socket }) do
    config  = conn.config()
    payload = query.payload |> to_line()

    :ok = :gen_udp.send(
      udp_socket,
      config[:host] |> to_char_list(),
      config[:port_udp],
      to_char_list(payload)
    )

    { 200, [], "" }  # always ":ok"
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> Encoder.encode()
end
