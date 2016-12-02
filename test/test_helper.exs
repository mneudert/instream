Code.require_file("helpers/nil_logger.exs", __DIR__)

Code.require_file("helpers/connection.exs", __DIR__)
Code.require_file("helpers/connection_with_opts.exs", __DIR__)
Code.require_file("helpers/env_connection.exs", __DIR__)
Code.require_file("helpers/log_connection.exs", __DIR__)
Code.require_file("helpers/udp_connection.exs", __DIR__)

Code.require_file("helpers/anon_connection.exs", __DIR__)
Code.require_file("helpers/guest_connection.exs", __DIR__)
Code.require_file("helpers/invalid_connection.exs", __DIR__)
Code.require_file("helpers/invalid_db_connection.exs", __DIR__)
Code.require_file("helpers/not_found_connection.exs", __DIR__)
Code.require_file("helpers/query_auth_connection.exs", __DIR__)
Code.require_file("helpers/unreachable_connection.exs", __DIR__)


alias Instream.Admin.Database
alias Instream.TestHelpers


[
  TestHelpers.Connection.child_spec,
  TestHelpers.ConnectionWithOpts.child_spec,
  TestHelpers.EnvConnection.child_spec,
  TestHelpers.LogConnection.child_spec,
  TestHelpers.UDPConnection.child_spec,

  TestHelpers.AnonConnection.child_spec,
  TestHelpers.GuestConnection.child_spec,
  TestHelpers.InvalidConnection.child_spec,
  TestHelpers.InvalidDbConnection.child_spec,
  TestHelpers.NotFoundConnection.child_spec,
  TestHelpers.QueryAuthConnection.child_spec,
  TestHelpers.UnreachableConnection.child_spec
]
|> Supervisor.start_link(strategy: :one_for_one)


_ = "test_database" |> Database.drop()   |> TestHelpers.Connection.execute()
_ = "test_database" |> Database.create() |> TestHelpers.Connection.execute()


# configure and start ExUnit
config = ExUnit.configuration

version = TestHelpers.Connection.version
config  = case Version.parse(version) do
  :error       -> config
  { :ok, ver } ->
    config = unless Version.match?(ver, "~> 1.1.0") do
      Keyword.put(config, :exclude, [{ :influxdb_version, "1.1.0" } | config[:exclude] ])
    end

    config = unless Version.match?(ver, "~> 1.2.0") do
      Keyword.put(config, :exclude, [{ :influxdb_version, "1.2.0" } | config[:exclude] ])
    end

    config
end

IO.puts "Running tests for InfluxDB version: #{ version }"

ExUnit.start(config)
