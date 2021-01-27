defmodule Instream.InfluxDBv1.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection

  test "ping connection" do
    assert :pong = DefaultConnection.ping()
  end

  test "status connection" do
    assert :ok = DefaultConnection.status()
  end

  test "version connection" do
    assert is_binary(DefaultConnection.version())
  end
end
