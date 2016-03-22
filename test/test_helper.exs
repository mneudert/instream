Code.require_file("helpers/connection.exs", __DIR__)
Code.require_file("helpers/connection_with_opts.exs", __DIR__)
Code.require_file("helpers/json_connection.exs", __DIR__)
Code.require_file("helpers/udp_connection.exs", __DIR__)

Code.require_file("helpers/anon_connection.exs", __DIR__)
Code.require_file("helpers/guest_connection.exs", __DIR__)
Code.require_file("helpers/invalid_connection.exs", __DIR__)
Code.require_file("helpers/not_found_connection.exs", __DIR__)
Code.require_file("helpers/query_auth_connection.exs", __DIR__)
Code.require_file("helpers/unreachable_connection.exs", __DIR__)


alias Instream.Cluster.Database
alias Instream.TestHelpers


[
  TestHelpers.Connection.child_spec,
  TestHelpers.ConnectionWithOpts.child_spec,
  TestHelpers.JSONConnection.child_spec,
  TestHelpers.UDPConnection.child_spec,

  TestHelpers.AnonConnection.child_spec,
  TestHelpers.GuestConnection.child_spec,
  TestHelpers.InvalidConnection.child_spec,
  TestHelpers.NotFoundConnection.child_spec,
  TestHelpers.QueryAuthConnection.child_spec,
  TestHelpers.UnreachableConnection.child_spec
]
|> Supervisor.start_link(strategy: :one_for_one)


_ = "test_database" |> Database.drop()   |> TestHelpers.Connection.execute()
_ = "test_database" |> Database.create() |> TestHelpers.Connection.execute()


ExUnit.start()
