defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  alias Instream.Encoder.Line, as: Encoder

  @behaviour Instream.Writer

  def write(query, _opts, %{module: conn, udp_socket: udp_socket}) do
    config = conn.config()

    payload =
      query.payload
      |> Map.get(:points, [])
      |> Encoder.encode()

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
end
