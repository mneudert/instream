Code.require_file("helpers/connection.exs", __DIR__)


alias Instream.Admin.Database
alias Instream.TestHelpers


Supervisor.start_link(
  [ TestHelpers.Connection.child_spec ],
  strategy: :one_for_one
)


_ = "test_database" |> Database.drop()   |> TestHelpers.Connection.execute()
_ = "test_database" |> Database.create() |> TestHelpers.Connection.execute()


ExUnit.start()
