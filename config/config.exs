use Mix.Config

if Mix.env() == :test do
  alias Instream.TestHelpers

  config :logger, :console,
    format: "\n$time $metadata[$level] $levelpad$message\n",
    metadata: [:query_time, :response_status]

  config :instream, TestHelpers.Connections.DefaultConnection,
    auth: [username: "instream_test", password: "instream_test"],
    loggers: []

  config :instream, TestHelpers.Connections.GuestConnection,
    auth: [username: "instream_guest", password: "instream_guest"],
    loggers: []

  config :instream, TestHelpers.Connections.RanchSocketConnection,
    loggers: [],
    port: 0,
    scheme: "http+unix"

  config :instream, TestHelpers.Connections.UnixSocketConnection,
    auth: [username: "instream_test", password: "instream_test"],
    loggers: [],
    port: 0,
    scheme: "http+unix"
end
