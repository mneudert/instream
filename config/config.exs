use Mix.Config

if Mix.env() == :test do
  alias Instream.TestHelpers

  config :logger, :console,
    format: "\n$time $metadata[$level] $levelpad$message\n",
    metadata: [:query_time, :response_status]

  case System.get_env("INFLUXDB_TOKEN") do
    nil ->
      config :instream, TestHelpers.Connections.DefaultConnection,
        auth: [username: "instream_test", password: "instream_test"],
        database: "test_database",
        loggers: []

    token ->
      config :instream, TestHelpers.Connections.DefaultConnection,
        auth: [method: :token, token: token],
        bucket: "test_database",
        org: "instream_test",
        loggers: [],
        version: :v2
  end

  config :instream, TestHelpers.Connections.DefaultConnectionV2,
    auth: [method: :token, token: System.get_env("INFLUXDB_TOKEN")],
    bucket: "test_database",
    loggers: [],
    org: "instream_test",
    version: :v2

  config :instream, TestHelpers.Connections.GuestConnection,
    auth: [username: "instream_guest", password: "instream_guest"],
    database: "test_database",
    loggers: []

  config :instream, TestHelpers.Connections.RanchSocketConnection,
    database: "test_database",
    loggers: [],
    port: 0,
    scheme: "http+unix"

  case System.get_env("INFLUXDB_SOCKET") do
    nil ->
      :ok

    socket ->
      config :instream, TestHelpers.Connections.UnixSocketConnection,
        auth: [username: "instream_test", password: "instream_test"],
        database: "test_database",
        host: URI.encode_www_form(socket),
        loggers: [],
        port: 0,
        scheme: "http+unix"
  end
end
