defmodule Instream.Query.BuilderDeprecationsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder

  test "CREATE DATABASE IF NOT EXISTS" do
    stderr = capture_io :stderr, fn ->
      query =
           Builder.create_database("some_database")
        |> Builder.if_not_exists()
        |> InfluxQL.encode()

      assert query == "CREATE DATABASE IF NOT EXISTS some_database"
    end

    assert String.contains?(stderr, "deprecated")
  end
end
