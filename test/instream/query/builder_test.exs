defmodule Instream.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder

  test "SELECT *" do
    query_default =
         Builder.from("some_measurement")
      |> InfluxQL.encode()

    query_select =
         Builder.from("some_measurement")
      |> Builder.select()
      |> InfluxQL.encode()

    assert query_select == query_default
    assert query_select == "SELECT * FROM some_measurement"
  end

  test "SELECT Enum.t" do
    query =
         Builder.from("some_measurement")
      |> Builder.select([ "one", "or", "more", "fields" ])
      |> InfluxQL.encode()

    assert query == "SELECT one, or, more, fields FROM some_measurement"
  end

  test "SELECT String.t" do
    query =
         Builder.from("some_measurement")
      |> Builder.select("one, or, more, fields")
      |> InfluxQL.encode()

    assert query == "SELECT one, or, more, fields FROM some_measurement"
  end
end
