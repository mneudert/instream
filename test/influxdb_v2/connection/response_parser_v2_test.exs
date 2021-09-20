defmodule Instream.Connection.ResponseParserV2Test do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  alias Instream.Connection.ResponseParserV2

  test "raw csv response" do
    error = "text"
    response = {:ok, 200, [{"Content-Type", "application/csv"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV2.maybe_parse(response, DefaultConnection, parse_opts)
  end

  test "raw json error response" do
    error = "text"
    response = {:ok, 500, [{"Content-Type", "application/json"}], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV2.maybe_parse(response, DefaultConnection, parse_opts)
  end

  test "raw non-json error response" do
    error = "text"
    response = {:ok, 500, [], error}
    parse_opts = [result_as: :raw]

    assert ^error = ResponseParserV2.maybe_parse(response, DefaultConnection, parse_opts)
  end
end
