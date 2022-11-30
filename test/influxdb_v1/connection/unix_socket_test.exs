defmodule Instream.InfluxDBv1.Connection.UnixSocketTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"
  @moduletag :unix_socket

  defmodule UnixSocketConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        auth: [username: "instream_test", password: "instream_test"],
        database: "test_database",
        init: {__MODULE__, :init},
        loggers: [],
        port: 0,
        scheme: "http+unix"
      ]

    def init(conn) do
      config = [host: "INFLUXDB_V1_SOCKET" |> System.fetch_env!() |> URI.encode_www_form()]

      Application.put_env(:instream, conn, config)
    end
  end

  test "unix socket: ping connection" do
    start_supervised!(UnixSocketConnection)

    assert :pong = UnixSocketConnection.ping()
  end

  test "unix socket: status connection" do
    start_supervised!(UnixSocketConnection)

    assert :ok = UnixSocketConnection.status()
  end

  test "unix socket: version connection" do
    start_supervised!(UnixSocketConnection)

    assert is_binary(UnixSocketConnection.version())
  end

  test "unix socket: read using database in query string" do
    start_supervised!(UnixSocketConnection)

    database = UnixSocketConnection.config(:database)

    query_in = ~s(SELECT value FROM "#{database}"."autogen"."empty_measurement")
    query_out = "SELECT value FROM empty_measurement"

    result_in = UnixSocketConnection.query(query_in)
    result_out = UnixSocketConnection.query(query_out)

    assert ^result_in = result_out
  end
end
