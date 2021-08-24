alias Instream.TestHelpers.Connections.DefaultConnection

config = ExUnit.configuration()

# configure unix socket connection tests
config =
  case System.get_env("INFLUXDB_SOCKET") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_SOCKET' not set, skipping unix socket tests")

      Keyword.put(config, :exclude, [:unix_socket | (config[:exclude] || [])])

    _ ->
      config
  end

# configure UDP writer tests
config =
  case System.get_env("INFLUXDB_PORT_UDP") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_PORT_UDP' not set, skipping UDP writer tests")
      Keyword.put(config, :exclude, [:udp | (config[:exclude] || [])])

    _ ->
      config
  end

# configure InfluxDB test version
version = System.get_env("INFLUXDB_VERSION")

version_excludes =
  case version do
    "1.7" -> [:"influxdb_exclude_1.7", :"influxdb_include_2.0", :"influxdb_include_1.8"]
    "1.8" -> [:"influxdb_exclude_1.8", :"influxdb_include_2.0", :"influxdb_include_1.7"]
    "2.0" -> [:"influxdb_exclude_2.0", :"influxdb_include_1.8", :"influxdb_include_1.7"]
  end

config = Keyword.put(config, :exclude, version_excludes ++ (config[:exclude] || []))

IO.puts("Running tests for InfluxDB version: #{version}")

unless "2.0" == version do
  _ = DefaultConnection.query("DROP DATABASE test_database", method: :post)
  _ = DefaultConnection.query("CREATE DATABASE test_database", method: :post)
end

# start ExUnit
Mox.defmock(Instream.TestHelpers.HTTPClientMock, for: Instream.HTTPClient)

ExUnit.start(config)
