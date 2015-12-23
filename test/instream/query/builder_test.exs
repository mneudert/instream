defmodule Instream.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder

  defmodule BuilderSeries do
    use Instream.Series

    series do
      measurement :some_measurement

      tag :foo
      tag :baz

      field :bar
      field :bat
    end
  end


  test "SELECT *" do
    query_default =
         BuilderSeries
      |> Builder.from()
      |> InfluxQL.encode()

    query_select =
         BuilderSeries
      |> Builder.from()
      |> Builder.select()
      |> InfluxQL.encode()

    assert query_select == query_default
    assert query_select == "SELECT * FROM some_measurement"
  end

  test "SELECT * WHERE foo = bar" do
    fields = %{ binary: "value", numeric: 42 }
    query  =
         BuilderSeries
      |> Builder.from()
      |> Builder.select()
      |> Builder.where(fields)
      |> InfluxQL.encode()

    assert query == "SELECT * FROM some_measurement WHERE binary = 'value' AND numeric = 42"
  end

  test "SELECT Enum.t" do
    query =
         BuilderSeries
      |> Builder.from()
      |> Builder.select([ "one field", "or", :more ])
      |> InfluxQL.encode()

    assert query == "SELECT \"one field\", or, more FROM some_measurement"
  end

  test "SELECT String.t" do
    query =
         BuilderSeries
      |> Builder.from()
      |> Builder.select("one, or, more, fields")
      |> InfluxQL.encode()

    assert query == "SELECT one, or, more, fields FROM some_measurement"
  end
end
