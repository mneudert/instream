defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.
  """

  alias Instream.Encoder.Line, as: Encoder

  @behaviour Instream.Writer

  def init_worker(state) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])

    Map.put(state, :udp_socket, socket)
  end

  def terminate_worker(%{udp_socket: socket}), do: :gen_udp.close(socket)

  def write(%{payload: %{points: [_ | _] = points}}, _opts, %{
        module: conn,
        udp_socket: udp_socket
      }) do
    config = conn.config()
    payload = Encoder.encode(points)

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

  def write(_, _, _), do: {200, [], ""}
end
