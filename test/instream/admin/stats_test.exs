defmodule Instream.Admin.StatsTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Stats
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "stats listing" do
    result = Stats.show() |> DefaultConnection.execute()

    %{ results: [%{ series: stats }]} = result

    assert %{ name: _, columns: _, values: _ } = hd(stats)
  end
end
