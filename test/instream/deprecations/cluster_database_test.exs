defmodule Instream.Deprecations.ClusterDatabaseTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Cluster.Database

  test "create" do
    stderr = capture_io :stderr, fn ->
      Database.create("deprecated")
    end

    assert String.contains?(stderr, "renamed")
  end

  test "drop" do
    stderr = capture_io :stderr, fn ->
      Database.drop("deprecated")
    end

    assert String.contains?(stderr, "renamed")
  end

  test "show" do
    stderr = capture_io :stderr, fn ->
      Database.show()
    end

    assert String.contains?(stderr, "renamed")
  end
end
