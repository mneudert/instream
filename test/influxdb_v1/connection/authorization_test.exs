defmodule Instream.InfluxDBv1.Connection.AuthorizationTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"

  defmodule UnauthorizedConnection do
    use Instream.Connection,
      config: [
        auth: [username: "unauthorized", password: "unauthorized"],
        database: "ignored",
        loggers: []
      ]
  end

  test "query without authorization" do
    assert %{error: "authorization failed"} =
             UnauthorizedConnection.query("SELECT * FROM read_data_privileges")

    assert %{error: "authorization failed"} =
             UnauthorizedConnection.query("DROP DATABASE ignored", method: :post)
  end

  test "write without authorization" do
    data = [
      %{
        measurement: "write_data_privileges",
        fields: %{value: 0.66}
      }
    ]

    assert %{error: "authorization failed"} = UnauthorizedConnection.write(data)
  end
end
