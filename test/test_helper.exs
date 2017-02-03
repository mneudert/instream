alias Instream.Admin.Database
alias Instream.TestHelpers

# grab ALL helpers and start connections
File.ls!("test/helpers")
|> Enum.filter( &String.contains?(&1, "connection") )
|> Enum.map(fn (helper) ->
     conn =
       helper
       |> String.replace(".ex", "")
       |> String.replace("udp", "UDP") # adjust camelize behaviour
       |> Macro.camelize()

     Module.concat([ Instream.TestHelpers, conn ]).child_spec
   end)
|> Supervisor.start_link(strategy: :one_for_one)


# setup test database
_ = "test_database" |> Database.drop()   |> TestHelpers.Connection.execute()
_ = "test_database" |> Database.create() |> TestHelpers.Connection.execute()


# hook up custom hackney pool
Application.put_env(:hackney, :pool_handler, TestHelpers.HackneyPool)


# start up inets fake influxdb server
root          = to_char_list(__DIR__)
httpd_config  = [
  document_root: root,
  modules:       [:instream_testhelpers_inets_proxy],
  port:          0,
  server_name:   'instream_testhelpers_inets_proxy',
  server_root:   root
]

{ :ok, httpd_pid } = :inets.start(:httpd, httpd_config)

inets_env =
  :instream
  |> Application.get_env(TestHelpers.InetsConnection)
  |> Keyword.put(:port, :httpd.info(httpd_pid)[:port])

Application.put_env(:instream, TestHelpers.InetsConnection, inets_env)


# configure InfluxDB test exclusion
config = ExUnit.configuration

version = TestHelpers.Connection.version
config  = case Version.parse(version) do
  :error           -> config
  { :ok, version } ->
    versions = [ "1.1", "1.2", "1.3" ]
    config   = Keyword.put(config, :exclude, config[:exclude] || [])

    Enum.reduce versions, config, fn (ver, acc) ->
      case Version.match?(version, "~> #{ ver }") do
        true  -> acc
        false -> Keyword.put(acc, :exclude, [{ :influxdb_version, ver } | acc[:exclude] ])
      end
    end
end

IO.puts "Running tests for InfluxDB version: #{ version }"


# configure OTP test exclusion
release          = :otp_release |> :erlang.system_info() |> to_string()
{ :ok, version } = Version.parse("#{ release }.0.0")
versions         = [ "19.0" ]

config = Enum.reduce versions, config, fn (ver, acc) ->
  case Version.match?(version, "~> #{ ver }") do
    true  -> acc
    false -> Keyword.put(acc, :exclude, [{ :otp_release, ver } | acc[:exclude] ])
  end
end

IO.puts "Running tests for OTP release: #{ release }"


# start ExUnit
ExUnit.start(config)
