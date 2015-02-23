Code.require_file("helpers/connection.exs", __DIR__)


alias Instream.TestHelpers


Supervisor.start_link(
  [ TestHelpers.Connection.child_spec ],
  strategy: :one_for_one
)


ExUnit.start()
