defmodule Instream.ResponseTest do
  use ExUnit.Case, async: true

  alias Instream.Response
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "response format: default (parsed)" do
    response = DefaultConnection.execute("SHOW DATABASES")

    assert is_map(response)
  end

  test "response format: csv" do
    response = DefaultConnection.execute("SHOW DATABASES", result_as: :csv)

    assert is_binary(response)
    assert "name," <> _ = response
  end

  test "response format: raw" do
    response = DefaultConnection.execute("SHOW DATABASES", result_as: :raw)

    assert is_binary(response)
    assert "{" <> _ = response
  end

  test "raw json error response" do
    error = "text"
    response = {500, [{"Content-Type", "application/json"}], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = Response.maybe_parse(response, parse_opts)
  end

  test "raw non-json error response" do
    error = "text"
    response = {500, [], error}
    parse_opts = [json_decoder: Jason, result_as: :raw]

    assert ^error = Response.maybe_parse(response, parse_opts)
  end

  test "regular non-json response" do
    response = "text"
    parse_opts = [json_decoder: Jason]

    assert ^response = Response.maybe_parse({200, [], response}, parse_opts)
  end
end
