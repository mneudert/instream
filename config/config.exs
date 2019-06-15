use Mix.Config

if Mix.env() == :test do
  alias Instream.TestHelpers

  config :logger, :console,
    format: "\n$time $metadata[$level] $levelpad$message\n",
    metadata: [:query_time, :response_status]

  connections =
    File.ls!("test/helpers/connections")
    |> Enum.filter(&String.contains?(&1, "connection"))
    |> Enum.map(fn helper ->
      # adjust camelize behaviour
      conn =
        helper
        |> String.replace(".ex", "")
        |> Macro.camelize()

      Module.concat([TestHelpers.Connections, conn])
    end)

  # setup authentication defaults
  Enum.each(connections, fn connection ->
    config :instream, connection, auth: [username: "instream_test", password: "instream_test"]
  end)

  # setup logging defaults
  connections
  |> Enum.reject(&(&1 == TestHelpers.Connections.LogConnection))
  |> Enum.each(fn connection ->
    config :instream, connection, loggers: []
  end)

  # connection specific configuration
  config :instream, TestHelpers.Connections.GuestConnection,
    auth: [username: "instream_guest", password: "instream_guest"]
end
