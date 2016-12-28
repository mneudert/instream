defmodule Instream.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder

  defmodule BuilderSeries do
    use Instream.Series

    series do
      measurement "some_measurement"

      tag :foo
      tag :baz

      field :bar
      field :bat
    end
  end

  test "CREATE DATABASE" do
    query =
         Builder.create_database("some_database")
      |> InfluxQL.encode()

    assert query == "CREATE DATABASE some_database"
  end

  test "CREATE RETENTION POLICY" do
    query =
         Builder.create_retention_policy("some_policy")
      |> Builder.on("some_database")
      |> Builder.duration("1h")
      |> Builder.replication(3)
      |> InfluxQL.encode()

    assert query == "CREATE RETENTION POLICY some_policy ON some_database DURATION 1h REPLICATION 3"
  end

  test "CREATE RETENTION POLICY DEFAULT" do
    query =
         Builder.create_retention_policy("some_policy")
      |> Builder.on("some_database")
      |> Builder.duration("1h")
      |> Builder.replication(3)
      |> Builder.default()
      |> InfluxQL.encode()

    assert query == "CREATE RETENTION POLICY some_policy ON some_database DURATION 1h REPLICATION 3 DEFAULT"
  end


  test "DROP DATABASE" do
    query =
         Builder.drop_database("some_database")
      |> InfluxQL.encode()

    assert query == "DROP DATABASE some_database"
  end

  test "DROP RETENTION POLICY" do
    query =
         Builder.drop_retention_policy("some_policy")
      |> Builder.on("some_database")
      |> InfluxQL.encode()

    assert query == "DROP RETENTION POLICY some_policy ON some_database"
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

  test "SELECT * using WHERE with empty fields" do
    keyword_query =
         BuilderSeries
      |> Builder.from()
      |> Builder.where([])
      |> InfluxQL.encode()

    map_query =
         BuilderSeries
      |> Builder.from()
      |> Builder.where(%{})
      |> InfluxQL.encode()

    should_query = "SELECT * FROM some_measurement"

    assert keyword_query == map_query
    assert keyword_query == should_query
    assert map_query     == should_query
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

  test "SELECT * WHERE foo = bar LIMIT x" do
    fields = %{ binary: "value", numeric: 42 }
    limit = 10
    query  =
         BuilderSeries
      |> Builder.from()
      |> Builder.select()
      |> Builder.where(fields)
      |> Builder.limit(limit)
      |> InfluxQL.encode()

    assert query == "SELECT * FROM some_measurement WHERE binary = 'value' AND numeric = 42 LIMIT 10"
  end

  test "SELECT * WHERE foo = bar LIMIT x OFFSET y" do
    fields = %{ binary: "value", numeric: 42 }
    limit = 10
    offset = 25
    query  =
         BuilderSeries
      |> Builder.from()
      |> Builder.select()
      |> Builder.where(fields)
      |> Builder.limit(limit)
      |> Builder.offset(offset)
      |> InfluxQL.encode()

    assert query == "SELECT * FROM some_measurement WHERE binary = 'value' AND numeric = 42 LIMIT 10 OFFSET 25"
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


  test "SHOW DIAGNOSTICS" do
    query =
         Builder.show(:diagnostics)
      |> InfluxQL.encode()

    assert query == "SHOW DIAGNOSTICS"
  end

  test "SHOW MEASUREMENTS" do
    query =
         Builder.show(:measurements)
      |> InfluxQL.encode()

    assert query == "SHOW MEASUREMENTS"
  end

  test "SHOW RETENTION POLICIES" do
    query =
         Builder.show(:retention_policies)
      |> Builder.on("some_database")
      |> InfluxQL.encode()

    assert query == "SHOW RETENTION POLICIES ON some_database"
  end

  test "SHOW STATS" do
    query =
         Builder.show(:stats)
      |> InfluxQL.encode()

    assert query == "SHOW STATS"
  end
end
