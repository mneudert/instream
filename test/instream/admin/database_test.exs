defmodule Instream.Admin.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Database
  alias Instream.TestHelpers.Connections.DefaultConnection

  @database "test_database_lifecycle"

  test "database lifecycle" do
    _ = @database |> Database.drop() |> DefaultConnection.execute()

    # create test database
    creation = @database |> Database.create() |> DefaultConnection.execute()
    listing  = Database.show() |> DefaultConnection.execute()

    assert %{results: [%{}]} = creation
    assert %{results: [%{series: [%{columns: ["name"], values: listing_values}]}]} = listing

    assert Enum.any?(listing_values, fn ([ db ]) -> db == @database end)

    # delete test database
    deletion = @database |> Database.drop() |> DefaultConnection.execute()
    listing  = Database.show() |> DefaultConnection.execute()

    assert %{results: [%{}]} = deletion
    assert %{results: [%{series: [ listing_rows ]}]} = listing

    case listing_rows[:values] do
      nil    -> assert true == true
      values -> refute Enum.any?(values, fn ([ db ]) -> db == @database end)
    end
  end


  test "database creation cases" do
    _ = @database |> Database.drop() |> DefaultConnection.execute()
    _ = @database |> Database.create() |> DefaultConnection.execute()

    # (implicit) if not exists
    result =
         @database
      |> Database.create()
      |> DefaultConnection.execute()

    assert %{results: [%{}]} = result
  end
end
