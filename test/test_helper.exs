alias Instream.TestHelpers.TestConnection

config = ExUnit.configuration()

# configure InfluxDB test version
version = System.get_env("INFLUXDB_VERSION")

version_excludes =
  case version do
    "1.7" -> [:"influxdb_exclude_1.7", :"influxdb_include_2.x", :"influxdb_include_1.8"]
    "1.8" -> [:"influxdb_exclude_1.8", :"influxdb_include_2.x", :"influxdb_include_1.7"]
    "2.0" -> [:"influxdb_exclude_2.0", :"influxdb_include_1.8", :"influxdb_include_1.7"]
    "2.1" -> [:"influxdb_exclude_2.1", :"influxdb_include_1.8", :"influxdb_include_1.7"]
    _ -> raise RuntimeError, "Required environment variable 'INFLUXDB_VERSION' not set!"
  end

config = Keyword.put(config, :exclude, version_excludes ++ (config[:exclude] || []))

IO.puts("Running tests for InfluxDB version: #{version}")

# configure InfluxDB connection
if version in ["2.0", "2.1"] do
  unless System.get_env("INFLUXDB_TOKEN") do
    raise RuntimeError, "Required environment variable 'INFLUXDB_TOKEN' not set!"
  end

  Application.put_env(
    :instream,
    TestConnection,
    auth: [method: :token, token: System.get_env("INFLUXDB_TOKEN")],
    bucket: "test_database",
    org: "instream_test",
    loggers: [],
    version: :v2
  )
else
  Application.put_env(
    :instream,
    TestConnection,
    auth: [username: "instream_test", password: "instream_test"],
    database: "test_database",
    loggers: []
  )

  _ = TestConnection.query("DROP DATABASE test_database", method: :post)
  _ = TestConnection.query("CREATE DATABASE test_database", method: :post)
end

# configure unix socket connection tests
config =
  case System.get_env("INFLUXDB_SOCKET") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_SOCKET' not set, skipping unix socket tests")

      Keyword.put(config, :exclude, [:unix_socket | config[:exclude]])

    _ ->
      config
  end

# configure UDP writer tests
config =
  case System.get_env("INFLUXDB_PORT_UDP") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_PORT_UDP' not set, skipping UDP writer tests")
      Keyword.put(config, :exclude, [:udp | config[:exclude]])

    _ ->
      config
  end

# start ExUnit
Mox.defmock(Instream.TestHelpers.HTTPClientMock, for: Instream.HTTPClient)

ExUnit.start(config)
