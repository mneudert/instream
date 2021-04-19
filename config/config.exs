use Mix.Config

if Mix.env() == :test do
  alias Instream.TestHelpers.Connections.DefaultConnection

  config :logger, :console,
    format: "\n$time $metadata[$level] $levelpad$message\n",
    metadata: [:query_time, :response_status]

  case System.get_env("INFLUXDB_TOKEN") do
    nil ->
      config :instream, DefaultConnection,
        auth: [username: "instream_test", password: "instream_test"],
        database: "test_database",
        loggers: []

    token ->
      config :instream, DefaultConnection,
        auth: [method: :token, token: token],
        bucket: "test_database",
        org: "instream_test",
        loggers: [],
        version: :v2
  end
end
