defmodule Instream.InfluxDBv2.Connection.BucketOrgTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  import Mox

  alias Instream.TestHelpers.HTTPClientMock

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

  defmodule DefaultSeries do
    use Instream.Series

    series do
      measurement "default_series"

      tag :foo, default: :bar
      field :value, default: 100
    end
  end

  test "query database priority" do
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

    MockConnection.query("--ignored--")
    MockConnection.query("--ignored--", bucket: "override_bucket", org: "override_org")
  end

  test "write database priority" do
    url_default = "http://localhost:8086/api/v2/write?bucket=default_bucket&org=default_org"
    url_override = "http://localhost:8086/api/v2/write?bucket=default_bucket&org=default_org"

    HTTPClientMock
    |> expect(:request, fn :post, ^url_default, _, _, _ -> {:ok, 200, [], ""} end)
    |> expect(:request, fn :post, ^url_override, _, _, _ -> {:ok, 200, [], ""} end)

    MockConnection.write(%DefaultSeries{})
    MockConnection.write(%DefaultSeries{}, bucket: "default_bucket", org: "default_org")
  end
end
