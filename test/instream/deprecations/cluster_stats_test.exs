defmodule Instream.Deprecations.ClusterStatsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Cluster.Stats

  test "show" do
    stderr = capture_io :stderr, fn ->
      Stats.show()
    end

    assert String.contains?(stderr, "renamed")
  end
end
