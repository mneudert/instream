defmodule Instream.Cluster.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.TestHelpers.Connection

  @database "test_database_lifecycle"

  test "database lifecycle" do
    _ = @database |> Database.drop() |> Connection.execute()

    # create test database
    creation = @database |> Database.create() |> Connection.execute()
    listing  = Database.show() |> Connection.execute()

    assert creation == %{results: [%{}]}
    assert %{results: [%{series: [%{columns: ["name"], values: listing_values}]}]} = listing

    assert Enum.any?(listing_values, fn ([ db ]) -> db == @database end)

    # delete test database
    deletion = @database |> Database.drop() |> Connection.execute()
    listing  = Database.show() |> Connection.execute()

    assert deletion == %{results: [%{}]}
    assert %{results: [%{series: [ listing_rows ]}]} = listing

    case listing_rows[:values] do
      nil    -> assert true == true
      values -> refute Enum.any?(values, fn ([ db ]) -> db == @database end)
    end
  end
end
