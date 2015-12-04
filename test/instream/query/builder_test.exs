defmodule Instream.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder

  test "SELECT" do
    query =
         Builder.from("some_measurement")
      |> Builder.select("one, or, more, fields")
      |> InfluxQL.encode()

    assert query == "SELECT one, or, more, fields FROM some_measurement"
  end
end
