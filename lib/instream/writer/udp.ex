defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  use Instream.Writer

  alias Instream.Encoder.Line, as: Encoder
  alias Instream.Util


  def write(query, _opts, %{ module: conn, udp_socket: udp_socket }) do
    config  = conn.config()
    payload = query.payload |> to_line()

    :ok = :gen_udp.send(
      udp_socket,
      Util.to_charlist(config[:host]),
      config[:port_udp],
      Util.to_charlist(payload)
    )

    { 200, [], "" }  # always ":ok"
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> Encoder.encode()
end
