alias Instream.TestHelpers.Connections

config = ExUnit.configuration()

# grab ALL helpers and start connections
File.ls!("test/helpers/connections")
|> Enum.filter(&String.contains?(&1, "connection"))
|> Enum.map(fn helper ->
  conn =
    helper
    |> String.replace(".ex", "")
    |> Macro.camelize()

  Module.concat(Connections, conn)
end)
|> Supervisor.start_link(strategy: :one_for_one)

# setup test database
_ = Connections.DefaultConnection.query("DROP DATABASE test_database", method: :post)
_ = Connections.DefaultConnection.query("CREATE DATABASE test_database", method: :post)

# configure unix socket connection
config =
  case System.get_env("INFLUXDB_SOCKET") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_SOCKET' not set, skipping unix socket tests")

      Keyword.put(config, :exclude, [:unix_socket | config[:exclude]])

    influxdb_socket ->
      socket_env =
        :instream
        |> Application.get_env(Connections.UnixSocketConnection)
        |> Keyword.put(:host, URI.encode_www_form(influxdb_socket))

      Application.put_env(:instream, Connections.UnixSocketConnection, socket_env)

      config
  end

# configure InfluxDB test exclusion
version = to_string(Connections.DefaultConnection.version())

config =
  case Version.parse(version) do
    :error ->
      config

    {:ok, version} ->
      versions = ["1.4", "1.5", "1.6", "1.7"]
      config = Keyword.put(config, :exclude, config[:exclude] || [])

      Enum.reduce(versions, config, fn ver, acc ->
        if Version.match?(version, "~> #{ver}") do
          acc
        else
          Keyword.put(acc, :exclude, [:"influxdb_exclude_#{ver}" | acc[:exclude]])
        end
      end)
  end

IO.puts("Running tests for InfluxDB version: #{version}")

# start ExUnit
ExUnit.start(config)
