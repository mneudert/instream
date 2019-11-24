alias Instream.Admin.Database
alias Instream.TestHelpers.Connections

config = ExUnit.configuration()

# grab ALL helpers and start connections
File.ls!("test/helpers/connections")
|> Enum.filter(&String.contains?(&1, "connection"))
|> Enum.reject(&(&1 == "init_connection.ex"))
|> Enum.map(fn helper ->
  conn =
    helper
    |> String.replace(".ex", "")
    |> String.replace("udp", "UDP")
    |> Macro.camelize()

  Module.concat(Connections, conn)
end)
|> Supervisor.start_link(strategy: :one_for_one)

# setup test database
_ = "test_database" |> Database.drop() |> Connections.DefaultConnection.execute()
_ = "test_database" |> Database.create() |> Connections.DefaultConnection.execute()

# start up inets fake influxdb server
root = String.to_charlist(__DIR__)

httpd_config = [
  document_root: root,
  modules: [Instream.TestHelpers.Inets.Handler],
  port: 0,
  server_name: 'instream_testhelpers_inets_handler',
  server_root: root
]

{:ok, httpd_pid} = :inets.start(:httpd, httpd_config)

inets_env =
  :instream
  |> Application.get_env(Connections.InetsConnection)
  |> Keyword.put(:port, :httpd.info(httpd_pid)[:port])

Application.put_env(:instream, Connections.InetsConnection, inets_env)

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
        case Version.match?(version, "~> #{ver}") do
          true -> acc
          false -> Keyword.put(acc, :exclude, [{:influxdb_version, ver} | acc[:exclude]])
        end
      end)
  end

IO.puts("Running tests for InfluxDB version: #{version}")

# configure OTP test exclusion
release = System.otp_release()
{:ok, version} = Version.parse("#{release}.0.0")
versions = ["19.0", "20.0"]

config =
  Enum.reduce(versions, config, fn ver, acc ->
    case Version.match?(version, ">= #{ver}.0") do
      true -> acc
      false -> Keyword.put(acc, :exclude, [{:otp_release, ver} | acc[:exclude]])
    end
  end)

IO.puts("Running tests for OTP release: #{release}")

# start ExUnit
ExUnit.start(config)
