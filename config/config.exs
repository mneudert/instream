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

  config :instream, TestHelpers.Connections.GuestConnection,
    auth: [username: "instream_guest", password: "instream_guest"],
    database: "test_database",
    loggers: []
end
