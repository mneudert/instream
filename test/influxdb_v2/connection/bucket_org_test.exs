defmodule Instream.InfluxDBv2.Connection.BucketOrgTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  import Mox

  alias Instream.TestHelpers.HTTPClientMock
  alias Instream.TestHelpers.TestSeries

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

  test "query bucket/org priority" do
    url_default = "http://localhost:8086/api/v2/query?org=default_org"
    url_override = "http://localhost:8086/api/v2/query?org=override_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, _, _ -> {:ok, 200, [], ""} end)
    |> expect(:request, fn :post, ^url_override, _, _, _ -> {:ok, 200, [], ""} end)

    MockConnection.query("--ignored--")
    MockConnection.query("--ignored--", org: "override_org")
  end

  test "write bucket/org priority" do
    url_default = "http://localhost:8086/api/v2/write?bucket=default_bucket&org=default_org"
    url_override = "http://localhost:8086/api/v2/write?bucket=override_bucket&org=override_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, _, _ -> {:ok, 200, [], ""} end)
    |> expect(:request, fn :post, ^url_override, _, _, _ -> {:ok, 200, [], ""} end)

    MockConnection.write(%TestSeries{})
    MockConnection.write(%TestSeries{}, bucket: "override_bucket", org: "override_org")
  end
end
