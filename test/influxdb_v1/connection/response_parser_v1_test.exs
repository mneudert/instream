defmodule Instream.Connection.ResponseParserV1Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"
  @moduletag :"influxdb_exclude_2.1"
  @moduletag :"influxdb_exclude_2.2"

  alias Instream.Connection.ResponseParserV1

  test "raw json error response" do
    error = ~s({"error":"type error"})
    response = {:ok, 500, [{"Content-Type", "application/json"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw csv error response" do
    error = ~s(error\n"type error")
    response = {:ok, 500, [{"Content-Type", "application/csv"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw non-json error response" do
    error = "text"
    response = {:ok, 500, [], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw json response" do
    error = ~s({"some":"json"})
    response = {:ok, 200, [{"Content-Type", "application/json"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw csv response" do
    error = ~s(some\ncsv)
    response = {:ok, 200, [{"Content-Type", "application/csv"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "regular non-json response" do
    content = "text"
    response = {:ok, 200, [], content}

    assert ^content = ResponseParserV1.maybe_parse(response, TestConnection, [])
  end
end
