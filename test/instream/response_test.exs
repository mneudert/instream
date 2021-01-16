defmodule Instream.ResponseTest do
  use ExUnit.Case, async: true

  alias Instream.Response
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "response format: default (parsed)" do
    assert %{} = DefaultConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "response format: csv" do
    assert "name," <> _ = DefaultConnection.query("SHOW DATABASES", result_as: :csv)
  end

  test "response format: raw" do
    assert "{" <> _ = DefaultConnection.query("SHOW DATABASES", result_as: :raw)
  end

  test "raw json error response" do
    error = "text"
    response = {:ok, 500, [{"Content-Type", "application/json"}], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = Response.maybe_parse(response, DefaultConnection, parse_opts)
  end

  test "raw non-json error response" do
    error = "text"
    response = {:ok, 500, [], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = Response.maybe_parse(response, DefaultConnection, parse_opts)
  end

  @tag :"influxdb_exclude_2.0"
  test "regular non-json response" do
    response = "text"
    parse_opts = [json_decoder: Jason]

    assert ^response =
             Response.maybe_parse({:ok, 200, [], response}, DefaultConnection, parse_opts)
  end
end
