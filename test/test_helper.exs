alias Instream.Admin.Database
alias Instream.TestHelpers

# grab ALL helpers and start connections
File.ls!("test/helpers")
|> Enum.map(fn (helper) ->
     Code.require_file("helpers/#{helper}", __DIR__)
     helper
   end)
|> Enum.filter(&( String.contains?(&1, "connection") ))
|> Enum.map(fn (helper) ->
     conn =
       helper
       |> String.replace(".exs", "")
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
  :error       -> config
  { :ok, ver } ->
    config = Keyword.put(config, :exclude, config[:exclude] || [])

    config = case Version.match?(ver, "~> 1.1.0") do
      true  -> config
      false -> Keyword.put(config, :exclude, [{ :influxdb_version, "1.1.0" } | config[:exclude] ])
    end

    config = case Version.match?(ver, "~> 1.2.0") do
      true  -> config
      false -> Keyword.put(config, :exclude, [{ :influxdb_version, "1.2.0" } | config[:exclude] ])
    end

    config = case Version.match?(ver, "~> 1.3.0") do
      true  -> config
      false -> Keyword.put(config, :exclude, [{ :influxdb_version, "1.3.0" } | config[:exclude] ])
    end

    config
end

IO.puts "Running tests for InfluxDB version: #{ version }"

ExUnit.start(config)
