defmodule Instream.Admin.RetentionPolicyTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.RetentionPolicy
  alias Instream.TestHelpers.Connection

  @database "test_database"
  @rp_name  "rp_lifecycle"
  @rp_policy "DURATION 1h REPLICATION 1"

  test "retention policy lifecycle" do
    # create retention policy
    creation =
         RetentionPolicy.create(@rp_name, @database, @rp_policy)
      |> Connection.execute()

    listing = RetentionPolicy.show(@database) |> Connection.execute()

    assert creation == %{results: [%{}]}
    assert %{results: [%{series: [%{columns: ["name", "duration", "replicaN", "default"], values: listing_values}]}]} = listing

    assert Enum.any?(listing_values, fn ([ name, _, _, _ ]) -> name == @rp_name end)

    # delete retention policy
    deletion = RetentionPolicy.drop(@rp_name, @database) |> Connection.execute()
    listing  = RetentionPolicy.show(@database) |> Connection.execute()

    assert deletion == %{results: [%{}]}
    assert %{results: [%{series: [ listing_rows ]}]} = listing

    case listing_rows[:values] do
      nil    -> assert true == true
      values -> refute Enum.any?(values, fn ([ name, _, _, _ ]) -> name == @rp_name end)
    end
  end
end
