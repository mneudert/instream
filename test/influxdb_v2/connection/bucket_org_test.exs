defmodule Instream.InfluxDBv2.Connection.BucketOrgTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  import Mox

  alias Instream.TestHelpers.HTTPClientMock
  alias Instream.TestHelpers.Series.DefaultSeries

  setup :verify_on_exit!

  defmodule MockConnection do
    use Instream.Connection,
      config: [
        bucket: "default_bucket",
        http_client: HTTPClientMock,
        loggers: [],
        org: "default_org",
        version: :v2
      ]
  end

  test "query bucket/org priority (Flux)" do
    url_default = "http://localhost:8086/api/v2/query?org=default_org"
    url_override = "http://localhost:8086/api/v2/query?org=override_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, _, _ -> {:ok, 200, [], ""} end)
    |> expect(:request, fn :post, ^url_override, _, _, _ -> {:ok, 200, [], ""} end)

    MockConnection.query("--ignored--")
    MockConnection.query("--ignored--", org: "override_org")
  end

  test "query bucket/org priority (InfluxQL)" do
    url_default = "http://localhost:8086/api/v2/query?org=default_org"
    url_override = "http://localhost:8086/api/v2/query?org=override_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, body, _ ->
      assert %{"bucket" => "default_bucket"} = Jason.decode!(body)

      {:ok, 200, [], ""}
    end)
    |> expect(:request, fn :post, ^url_override, _, body, _ ->
      assert %{"bucket" => "override_bucket"} = Jason.decode!(body)

      {:ok, 200, [], ""}
    end)

    MockConnection.query("--ignored--", query_language: :influxql)

    MockConnection.query("--ignored--",
      bucket: "override_bucket",
      org: "override_org",
      query_language: :influxql
    )
  end

  test "write bucket/org priority" do
    url_default = "http://localhost:8086/api/v2/write?bucket=default_bucket&org=default_org"
    url_override = "http://localhost:8086/api/v2/write?bucket=default_bucket&org=default_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, _, _ -> {:ok, 200, [], ""} end)
    |> expect(:request, fn :post, ^url_override, _, _, _ -> {:ok, 200, [], ""} end)

    MockConnection.write(%DefaultSeries{})
    MockConnection.write(%DefaultSeries{}, bucket: "default_bucket", org: "default_org")
  end
end
