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


# configure and start ExUnit
config = ExUnit.configuration

version = TestHelpers.Connection.version
config  = case Version.parse(version) do
  :error           -> config
  { :ok, version } ->
    versions = [ "1.1.0", "1.2.0", "1.3.0" ]
    config   = Keyword.put(config, :exclude, config[:exclude] || [])

    Enum.reduce versions, config, fn (ver, acc) ->
      case Version.match?(version, "~> #{ ver }") do
        true  -> acc
        false -> Keyword.put(acc, :exclude, [{ :influxdb_version, ver } | acc[:exclude] ])
      end
    end
end

IO.puts "Running tests for InfluxDB version: #{ version }"

ExUnit.start(config)
