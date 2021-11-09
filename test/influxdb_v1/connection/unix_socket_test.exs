defmodule Instream.InfluxDBv1.Connection.UnixSocketTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"
  @moduletag :"influxdb_exclude_2.1"
  @moduletag :unix_socket

  defmodule UnixSocketConnection do
    use Instream.Connection,
      config: [
        auth: [username: "instream_test", password: "instream_test"],
        database: "test_database",
        host: URI.encode_www_form(System.get_env("INFLUXDB_SOCKET") || ""),
        loggers: [],
        port: 0,
        scheme: "http+unix"
      ]
  end

  test "unix socket: ping connection" do
    assert :pong = UnixSocketConnection.ping()
  end

  test "unix socket: status connection" do
    assert :ok = UnixSocketConnection.status()
  end

  test "unix socket: version connection" do
    assert is_binary(UnixSocketConnection.version())
  end

  test "unix socket: read using database in query string" do
    database = UnixSocketConnection.config(:database)

    query_in = ~s(SELECT value FROM "#{database}"."autogen"."empty_measurement")
    query_out = "SELECT value FROM empty_measurement"

    result_in = UnixSocketConnection.query(query_in)
    result_out = UnixSocketConnection.query(query_out)

    assert ^result_in = result_out
  end
end
