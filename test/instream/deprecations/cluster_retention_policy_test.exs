defmodule Instream.Deprecations.ClusterRetentionPolicyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Cluster.RetentionPolicy

  test "alter" do
    stderr = capture_io :stderr, fn ->
      RetentionPolicy.alter("name", "db", "pol")
    end

    assert String.contains?(stderr, "renamed")
  end

  test "create" do
    stderr = capture_io :stderr, fn ->
      RetentionPolicy.create("name", "db", "dur", 0)
    end

    assert String.contains?(stderr, "renamed")
  end

  test "drop" do
    stderr = capture_io :stderr, fn ->
      RetentionPolicy.drop("name", "db")
    end

    assert String.contains?(stderr, "renamed")
  end

  test "show" do
    stderr = capture_io :stderr, fn ->
      RetentionPolicy.show("db")
    end

    assert String.contains?(stderr, "renamed")
  end
end
