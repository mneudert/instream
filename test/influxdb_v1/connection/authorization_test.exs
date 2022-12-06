defmodule Instream.InfluxDBv1.Connection.AuthorizationTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"

  alias Instream.TestHelpers.TestConnection

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
          auth: [username: "unauthorized", password: "unauthorized"],
          database: "ignored",
          loggers: []
        )

      Application.put_env(:instream, conn, config)
    end
  end

  test "query without authorization" do
    start_supervised!(UnauthorizedConnection)

    assert %{error: "authorization failed"} =
             UnauthorizedConnection.query("SELECT * FROM read_data_privileges")

    assert %{error: "authorization failed"} =
             UnauthorizedConnection.query("DROP DATABASE ignored", method: :post)
  end

  test "write without authorization" do
    start_supervised!(UnauthorizedConnection)

    data = [
      %{
        measurement: "write_data_privileges",
        fields: %{value: 0.66}
      }
    ]

    assert %{error: "authorization failed"} = UnauthorizedConnection.write(data)
  end
end
