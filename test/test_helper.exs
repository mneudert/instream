Code.require_file("helpers/connection.exs", __DIR__)
Code.require_file("helpers/guest_connection.exs", __DIR__)


alias Instream.Cluster.Database
alias Instream.TestHelpers


[
  TestHelpers.Connection.child_spec,
  TestHelpers.GuestConnection.child_spec
]
|> Supervisor.start_link(strategy: :one_for_one)


_ = "test_database" |> Database.drop()   |> TestHelpers.Connection.execute()
_ = "test_database" |> Database.create() |> TestHelpers.Connection.execute()


ExUnit.start()
