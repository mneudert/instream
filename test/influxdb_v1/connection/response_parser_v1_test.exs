defmodule Instream.Connection.ResponseParserV1Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"

  alias Instream.Connection.ResponseParserV1
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "response format: default (parsed)" do
    assert %{} = DefaultConnection.query("SELECT * FROM ignore")
  end

  test "response format: csv" do
    assert Enum.member?(
             DefaultConnection.query("SHOW DATABASES", result_as: :csv),
             %{"name" => "test_database", "tags" => ""}
           )
  end

  test "response format: raw" do
    assert "{" <> _ = DefaultConnection.query("SELECT * FROM ignore", result_as: :raw)
  end

  test "raw json error response" do
    error = "text"
    response = {:ok, 500, [{"Content-Type", "application/json"}], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, DefaultConnection, parse_opts)
  end

  test "raw non-json error response" do
    error = "text"
    response = {:ok, 500, [], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, DefaultConnection, parse_opts)
  end

  test "regular non-json response" do
    response = "text"
    parse_opts = [json_decoder: Jason]

    assert ^response =
             ResponseParserV1.maybe_parse({:ok, 200, [], response}, DefaultConnection, parse_opts)
  end
end
