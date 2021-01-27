defmodule Instream.InfluxDBv2.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.0"

  alias Instream.TestHelpers.Connections.DefaultConnection

  test "mismatched InfluxDB version" do
    assert {:error, :version_mismatch} = DefaultConnection.ping()
    assert {:error, :version_mismatch} = DefaultConnection.status()
    assert {:error, :version_mismatch} = DefaultConnection.version()
  end
end
