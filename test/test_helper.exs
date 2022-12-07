alias Instream.TestHelpers.TestConnection

config = ExUnit.configuration()

# configure InfluxDB test version
version = System.fetch_env!("INFLUXDB_VERSION")

version_excludes =
  case version do
    "1.7" -> [:"influxdb_exclude_1.7", :"influxdb_include_2.x", :"influxdb_include_1.8"]
    "1.8" -> [:"influxdb_exclude_1.8", :"influxdb_include_2.x", :"influxdb_include_1.7"]
    "2.0" -> [:"influxdb_exclude_2.0", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "2.1" -> [:"influxdb_exclude_2.1", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "2.2" -> [:"influxdb_exclude_2.2", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "2.3" -> [:"influxdb_exclude_2.3", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "2.4" -> [:"influxdb_exclude_2.4", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "2.5" -> [:"influxdb_exclude_2.5", :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    "cloud" -> [:influxdb_exclude_cloud, :"influxdb_exclude_2.x", :"influxdb_include_1.x"]
    _ -> raise RuntimeError, "Unknown INFLUXDB_VERSION: #{inspect(version)}"
  end

config = Keyword.put(config, :exclude, version_excludes ++ (config[:exclude] || []))

IO.puts("Running tests for InfluxDB version: #{version}")

# configure InfluxDB connection
if version in ["2.0", "2.1", "2.2", "2.3", "2.4", "2.5", "cloud"] do
  config = [
    auth: [method: :token, token: System.fetch_env!("INFLUXDB_V2_TOKEN")],
    host: System.fetch_env!("INFLUXDB_HOST"),
    port: System.fetch_env!("INFLUXDB_PORT"),
    scheme: System.fetch_env!("INFLUXDB_SCHEME"),
    bucket: System.fetch_env!("INFLUXDB_V2_BUCKET"),
    database: System.fetch_env!("INFLUXDB_V2_DATABASE"),
    org: System.fetch_env!("INFLUXDB_V2_ORG"),
    loggers: [],
    version: :v2
  ]

  config =
    if "cloud" == version do
      Keyword.merge(config, http_opts: [recv_timeout: 10_000])
    else
      config
    end

  Application.put_env(:instream, TestConnection, config)
else
  database = System.fetch_env!("INFLUXDB_V1_DATABASE")

  Application.put_env(
    :instream,
    TestConnection,
    auth: [
      username: System.fetch_env!("INFLUXDB_V1_USERNAME"),
      password: System.fetch_env!("INFLUXDB_V1_PASSWORD")
    ],
    host: System.fetch_env!("INFLUXDB_HOST"),
    port: System.fetch_env!("INFLUXDB_PORT"),
    scheme: System.fetch_env!("INFLUXDB_SCHEME"),
    database: database,
    loggers: []
  )

  _ = TestConnection.query("DROP DATABASE #{database}", method: :post)
  _ = TestConnection.query("CREATE DATABASE #{database}", method: :post)
end

# configure unix socket connection tests
config =
  if version in ["1.8"] do
    _ = System.fetch_env!("INFLUXDB_V1_SOCKET")

    config
  else
    Keyword.put(config, :exclude, [:unix_socket | config[:exclude]])
  end

# configure UDP writer tests
config =
  if version in ["1.7", "1.8"] do
    _ = System.fetch_env!("INFLUXDB_V1_PORT_UDP")

    config
  else
    Keyword.put(config, :exclude, [:udp | config[:exclude]])
  end

# start ExUnit
Mox.defmock(Instream.TestHelpers.HTTPClientMock, for: Instream.HTTPClient)

ExUnit.start(config)
