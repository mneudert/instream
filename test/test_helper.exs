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

# configure InfluxDB v2 authorization token
:ok =
  case System.get_env("INFLUX_TOKEN") do
    nil ->
      :ok

    token ->
      token_env =
        :instream
        |> Application.get_env(Connections.DefaultConnection)
        |> Keyword.put(:auth, method: :token, token: token)

      Application.put_env(:instream, Connections.DefaultConnection, token_env)
  end

# configure InfluxDB test exclusion
conn_version =
  Connections.DefaultConnection.version()
  |> Kernel.to_string()
  |> Version.parse()

skip_versions =
  case conn_version do
    :error ->
      ["1.4", "1.5", "1.6", "1.7", "1.8"]

    {:ok, version} ->
      ["2.0" | Enum.filter(["1.4", "1.5", "1.6", "1.7"], &Version.match?(version, "~> #{&1}"))]
  end

version =
  case conn_version do
    :error -> "2.0"
    {:ok, ver} -> "#{ver.major}.#{ver.minor}"
  end

config = Keyword.put(config, :exclude, config[:exclude] || [])

config =
  Enum.reduce(skip_versions, config, fn skip_version, acc ->
    Keyword.put(acc, :exclude, [:"influxdb_exclude_#{skip_version}" | acc[:exclude]])
  end)

IO.puts("Running tests for InfluxDB version: #{version}")

# Configure DefaultConnection for :v2
if version == "2.0" do
  Application.put_env(
    :instream,
    Connections.DefaultConnection,
    :instream
    |> Application.get_env(Connections.DefaultConnection)
    |> Keyword.put(:version, :v2)
  )
end

# start ExUnit
ExUnit.start(config)
