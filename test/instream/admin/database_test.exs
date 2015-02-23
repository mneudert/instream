defmodule Instream.Admin.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Database
  alias Instream.TestHelpers.Connection

  @database "test_database"

  test "database lifecycle" do
    creation = @database |> Database.create() |> Connection.execute()
    listing  = Database.show() |> Connection.execute()

    assert creation == %{results: [%{}]}
    assert listing  == %{results: [%{rows: [%{columns: ["name"],values: [["test_database"]]}]}]}

    deletion = @database |> Database.drop() |> Connection.execute()

    assert deletion == %{results: [%{}]}
    assert listing  == %{results: [%{rows: [%{columns: ["name"],values: [["test_database"]]}]}]}
  end
end
