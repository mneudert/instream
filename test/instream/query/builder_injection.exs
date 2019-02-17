defmodule Instream.Query.BuilderInjectionTest do
  use ExUnit.Case, async: true

  alias Instream.Encoder.InfluxQL
  alias Instream.Query.Builder
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "SELECT InfluxQL Injection" do
    # result if escaping is broken:
    # %{error: "error parsing query: found  FROM injectable, expected FROM at line 1, char 29"}
    assert %{results: [_]} =
             "injectable"
             |> Builder.from()
             |> Builder.select(["some", ~S(broken ';stuff")])
             |> InfluxQL.encode()
             |> DefaultConnection.query(database: "test_database")
  end
end
