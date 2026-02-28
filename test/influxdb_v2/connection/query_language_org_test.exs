defmodule Instream.InfluxDBv2.Connection.QueryLanguageOrgTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  import Mox

  alias Instream.TestHelpers.HTTPClientMock

  setup :verify_on_exit!

  describe "v1 client" do
    defmodule MockConnectionV1 do
      use Instream.Connection,
        config: [
          bucket: "default_bucket",
          http_client: HTTPClientMock,
          loggers: [],
          org: "default_org",
          version: :v1,
          database: "mapped_database"
        ]
    end

    test "adds org to query params when using flux" do
      expected_url = "http://localhost:8086/api/v2/query?db=mapped_database&org=default_org"

      HTTPClientMock
      |> expect(:request, fn :post, ^expected_url, _, _, _ -> {:ok, 200, [], ""} end)

      MockConnectionV1.query("--ignored--", query_language: :flux)
    end

    test "doesn't add org to query params when using influxql" do
      expected_url = "http://localhost:8086/query?db=mapped_database&q=--ignored--"

      HTTPClientMock
      |> expect(:request, fn :get, ^expected_url, _, _, _ -> {:ok, 200, [], ""} end)

      MockConnectionV1.query("--ignored--", query_language: :influxql)
    end
  end

  describe "v2 client" do
    defmodule MockConnectionV2 do
      use Instream.Connection,
        config: [
          bucket: "default_bucket",
          http_client: HTTPClientMock,
          loggers: [],
          org: "default_org",
          version: :v2,
          database: "mapped_database"
        ]
    end

    test "adds org to query params when using flux" do
      expected_url = "http://localhost:8086/api/v2/query?org=default_org"

      HTTPClientMock
      |> expect(:request, fn :post, ^expected_url, _, _, _ -> {:ok, 200, [], ""} end)

      MockConnectionV2.query("--ignored--", query_language: :flux)
    end

    test "doesn't add org to query params when using influxql" do
      expected_url = "http://localhost:8086/query?db=mapped_database&q=--ignored--"

      HTTPClientMock
      |> expect(:request, fn :post, ^expected_url, _, _, _ -> {:ok, 200, [], ""} end)

      MockConnectionV2.query("--ignored--", query_language: :influxql)
    end
  end
end
