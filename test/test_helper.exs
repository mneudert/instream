alias Instream.TestHelpers.Connections

config = ExUnit.configuration()

# configure unix socket connection
config =
  case System.get_env("INFLUXDB_SOCKET") do
    nil ->
      IO.puts("Environment variable 'INFLUXDB_SOCKET' not set, skipping unix socket tests")

      Keyword.put(config, :exclude, [:unix_socket | config[:exclude]])

    _ ->
      config
  end

# configure InfluxDB test exclusion
conn_version =
  case Connections.DefaultConnection.config(:version) do
    :v1 ->
      Connections.DefaultConnection.version()
      |> Kernel.to_string()
      |> Version.parse()

    _ ->
      :error
  end

excludes =
  case conn_version do
    :error ->
      [:"influxdb_exclude_2.0", :"influxdb_include_1.8", :"influxdb_include_1.7"]

    {:ok, %{major: 1, minor: 8}} ->
      [:"influxdb_exclude_1.8", :"influxdb_include_2.0", :"influxdb_include_1.7"]

    {:ok, %{major: 1, minor: 7}} ->
      [:"influxdb_exclude_1.7", :"influxdb_include_2.0", :"influxdb_include_1.8"]
  end

version =
  case conn_version do
    :error -> "2.0"
    {:ok, ver} -> "#{ver.major}.#{ver.minor}"
  end

config = Keyword.put(config, :exclude, excludes ++ (config[:exclude] || []))

IO.puts("Running tests for InfluxDB version: #{version}")

unless "2.0" == version do
  _ = Connections.DefaultConnection.query("DROP DATABASE test_database", method: :post)
  _ = Connections.DefaultConnection.query("CREATE DATABASE test_database", method: :post)
end

# start ExUnit
Mox.defmock(Instream.TestHelpers.HTTPClientMock, for: Instream.HTTPClient)

ExUnit.start(config)
