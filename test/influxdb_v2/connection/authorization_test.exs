defmodule Instream.InfluxDBv2.Connection.AuthorizationTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  defmodule BearerAuthenticationConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__, :fetch_influxdb_auth},
        bucket: "test_bucket",
        org: "instream_test",
        loggers: [],
        version: :v2
      ]

    def fetch_influxdb_auth(_) do
      Application.put_env(:instream, __MODULE__,
        auth: [method: :bearer, token: System.fetch_env!("INFLUXDB_V2_TOKEN")]
      )
    end
  end

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

  describe ":bearer authentication" do
    @tag :"influxdb_exclude_2.1"
    @tag :"influxdb_exclude_2.2"
    @tag :"influxdb_exclude_2.3"
    @tag :"influxdb_exclude_2.4"
    @tag :"influxdb_exclude_2.5"
    test "influxdb v2.0" do
      assert BearerAuthenticationConnection.query(~S[from(bucket: "ignored")]) == %{
               code: "unauthorized",
               message: "unauthorized access"
             }
    end

    @tag :"influxdb_exclude_2.0"
    test "influxdb >= v2.1" do
      start_supervised!(BearerAuthenticationConnection)

      refute BearerAuthenticationConnection.query(~S[from(bucket: "ignored")]) == %{
               code: "unauthorized",
               message: "unauthorized access"
             }
    end
  end

  test "query without authorization" do
    assert %{code: "unauthorized", message: "unauthorized access"} =
             UnauthorizedConnection.query(~S[from(bucket: "ignored")])
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
