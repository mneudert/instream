defmodule Instream.Cluster.RetentionPolicyTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.RetentionPolicy
  alias Instream.TestHelpers.Connection

  @database "test_database"
  @rp_name  "rp_lifecycle"

  @rp_altered      "DURATION 2h REPLICATION 1"
  @rp_duration     "1h"
  @rp_replication  1

  test "retention policy lifecycle" do
    # create retention policy
    creation =
         @rp_name
      |> RetentionPolicy.create(@database, @rp_duration, @rp_replication)
      |> Connection.execute()

    listing = RetentionPolicy.show(@database) |> Connection.execute()

    assert creation == %{results: [%{}]}
    assert %{results: [%{series: [%{values: listing_values}]}]} = listing

    assert Enum.any?(listing_values, fn ([ name, duration, _, _, _ ]) ->
      name == @rp_name && duration == "1h0m0s"
    end)

    # alter retention polcy
    alteration =
         @rp_name
      |> RetentionPolicy.alter(@database, @rp_altered)
      |> Connection.execute()

    listing = RetentionPolicy.show(@database) |> Connection.execute()

    assert alteration == %{results: [%{}]}
    assert %{results: [%{series: [%{values: listing_values}]}]} = listing

    assert Enum.any?(listing_values, fn ([ name, duration, _, _, _ ]) ->
      name == @rp_name && duration == "2h0m0s"
    end)

    # delete retention policy
    deletion = RetentionPolicy.drop(@rp_name, @database) |> Connection.execute()
    listing  = RetentionPolicy.show(@database) |> Connection.execute()

    assert deletion == %{results: [%{}]}
    assert %{results: [%{series: [ listing_rows ]}]} = listing

    case listing_rows[:values] do
      nil    -> assert true == true
      values ->
        refute Enum.any?(values, fn ([ name, _, _, _, _ ]) ->
          name == @rp_name
        end)
    end
  end
end
