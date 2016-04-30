defmodule Instream.Deprecations.ClusterDiagnosticsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Cluster.Diagnostics

  test "show" do
    stderr = capture_io :stderr, fn ->
      Diagnostics.show()
    end

    assert String.contains?(stderr, "renamed")
  end
end
