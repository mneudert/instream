defmodule Instream.InfluxDBv2.Connection.AuthorizationTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  defmodule UnauthorizedConnection do
    use Instream.Connection,
      config: [
        auth: [method: :token, token: "--invalid--"],
        bucket: "ignored",
        org: "ignored",
        loggers: [],
        version: :v2
      ]
  end

  test "query without authorization" do
    assert %{code: "unauthorized", message: "unauthorized access"} =
             UnauthorizedConnection.query(~S|from(bucket: "ignored")|)
  end

  test "write without authorization" do
    data = [
      %{
        measurement: "write_data_privileges",
        fields: %{value: 0.66}
      }
    ]

    assert %{code: "unauthorized", message: "unauthorized access"} =
             UnauthorizedConnection.write(data)
  end
end
