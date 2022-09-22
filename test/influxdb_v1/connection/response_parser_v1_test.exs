defmodule Instream.Connection.ResponseParserV1Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"

  alias Instream.Connection.ResponseParserV1

  test "raw json error response" do
    error = ~S({"error":"type error"})
    response = {:ok, 500, [{"Content-Type", "application/json"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw csv error response" do
    error = ~S(error\n"type error")
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
    error = ~S({"some":"json"})
    response = {:ok, 200, [{"Content-Type", "application/json"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV1.maybe_parse(response, TestConnection, parse_opts)
  end

  test "raw csv response" do
    error = ~S(some\ncsv)
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
