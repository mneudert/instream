defmodule Instream.InfluxDBv2.Connection.AuthorizationTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  alias Instream.TestHelpers.TestConnection

  defmodule BearerAuthenticationConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__, :init}
      ]

    def init(conn) do
      config =
        Keyword.merge(
          TestConnection.config(),
          auth: [method: :bearer, token: TestConnection.config(:auth)[:token]],
          loggers: []
        )

      Application.put_env(:instream, conn, config)
    end
  end

  defmodule UnauthorizedConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__, :init}
      ]

    def init(conn) do
      config =
        Keyword.merge(
          TestConnection.config(),
          auth: [method: :token, token: "--invalid--"],
          bucket: "ignored",
          org: "ignored",
          loggers: []
        )

      Application.put_env(:instream, conn, config)
    end
  end

  describe ":bearer authentication" do
    @tag :"influxdb_exclude_2.1"
    @tag :"influxdb_exclude_2.2"
    @tag :"influxdb_exclude_2.3"
    @tag :"influxdb_exclude_2.4"
    @tag :"influxdb_exclude_2.5"
    @tag :"influxdb_exclude_2.6"
    @tag :"influxdb_exclude_2.7"
    test "influxdb v2.0" do
      start_supervised!(BearerAuthenticationConnection)

      assert %{
               code: "unauthorized",
               message: "unauthorized access"
             } =
               BearerAuthenticationConnection.query(
                 ~S[from(bucket: "ignored") |> range(start: -5m)]
               )
    end

    @tag :"influxdb_exclude_2.0"
    @tag :influxdb_exclude_cloud
    test "influxdb >= v2.1" do
      start_supervised!(BearerAuthenticationConnection)

      refute %{
               code: "unauthorized",
               message: "unauthorized access"
             } ==
               BearerAuthenticationConnection.query(
                 ~S[from(bucket: "ignored") |> range(start: -5m)]
               )
    end
  end

  test "query without authorization" do
    start_supervised!(UnauthorizedConnection)

    assert %{code: "unauthorized", message: "unauthorized access"} =
             UnauthorizedConnection.query(~S[from(bucket: "ignored") |> range(start: -5m)])
  end

  test "write without authorization" do
    start_supervised!(UnauthorizedConnection)

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
