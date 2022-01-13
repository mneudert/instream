defmodule Instream.Connection.BodyReadErrorTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.TestConnection

  defmodule RanchSocketConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        loggers: [],
        port: 0,
        scheme: "http+unix"
      ]
  end

  defmodule SocketProtocol do
    use GenServer

    @behaviour :ranch_protocol

    def start_link(ref, socket, transport, _opts) do
      pid = :proc_lib.spawn_link(__MODULE__, :init, [[ref, socket, transport]])

      {:ok, pid}
    end

    def init([ref, socket, transport]) do
      :ok = :ranch.accept_ack(ref)
      :ok = transport.setopts(socket, [{:active, true}])

      :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
    end

    def handle_info({:tcp, socket, _data}, %{socket: socket, transport: transport} = state) do
      transport.send(socket, "HTTP/99.99 200 OK\r\nContent-Length: 0\r\n\r\n")

      {:noreply, state}
    end

    def handle_info({:tcp_closed, socket}, %{socket: socket, transport: transport} = state) do
      transport.close(socket)

      {:stop, :normal, state}
    end
  end

  test "body read error" do
    socket = Path.expand("../../tmp/body_read.sock", __DIR__)

    socket
    |> Path.dirname()
    |> File.mkdir_p!()

    File.rm(socket)

    socket_env =
      Keyword.merge(
        TestConnection.config(),
        host: URI.encode_www_form(socket),
        port: 0,
        scheme: "http+unix"
      )

    Application.put_env(:instream, RanchSocketConnection, socket_env)

    :ranch.start_listener(
      :instream_body_read_test,
      :ranch_tcp,
      [port: 0, ip: {:local, socket}],
      SocketProtocol,
      []
    )

    point = %{
      measurement: "body_read_error",
      tags: %{tag: :test},
      fields: %{field: :test}
    }

    if :v1 == TestConnection.config(:version) do
      assert :error = RanchSocketConnection.ping()
      assert :error = RanchSocketConnection.status()
      assert :error = RanchSocketConnection.version()
    end

    assert {:error, :bad_request} = RanchSocketConnection.query("")
    assert {:error, :bad_request} = RanchSocketConnection.write(point)

    :ranch.stop_listener(:instream_body_read_test)
  end
end
