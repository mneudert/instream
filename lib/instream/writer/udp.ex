defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  @behaviour Instream.Writer

  alias Instream.Encoder.Line, as: Encoder

  def write(query, _opts, %{module: conn, udp_socket: udp_socket}) do
    config = conn.config()
    payload = query.payload |> to_line()

    :ok =
      :gen_udp.send(
        udp_socket,
        String.to_charlist(config[:host]),
        config[:port_udp],
        String.to_charlist(payload)
      )

    # always ":ok"
    {200, [], ""}
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> Encoder.encode()
end
