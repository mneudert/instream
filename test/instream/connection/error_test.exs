defmodule Instream.Connection.ErrorTest do
  use ExUnit.Case, async: true

  defmodule OptionsConnection do
    use Instream.Connection,
      config: [
        http_opts: [proxy: "http://invalidproxy"],
        loggers: []
      ]
  end

  defmodule UnreachableConnection do
    use Instream.Connection,
      config: [
        host: "some-really-unreachable-host",
        loggers: []
      ]
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "connection_error_tests"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end

  test "ping connection" do
    assert :error = OptionsConnection.ping()
    assert :error = UnreachableConnection.ping()
  end

  @tag :"influxdb_exclude_2.0"
  @tag :"influxdb_exclude_2.1"
  @tag :"influxdb_exclude_2.2"
  test "status connection" do
    assert :error = OptionsConnection.status()
    assert :error = UnreachableConnection.status()
  end

  @tag :"influxdb_exclude_2.0"
  @tag :"influxdb_exclude_2.1"
  @tag :"influxdb_exclude_2.2"
  test "version connection" do
    assert :error = OptionsConnection.version()
    assert :error = UnreachableConnection.version()
  end

  test "reading data from an unresolvable host" do
    query = "SELECT * FROM connection_error_tests"

    assert {:error, :nxdomain} = UnreachableConnection.query(query)
  end

  test "writing data to an unresolvable host" do
    data = %TestSeries{}

    assert {:error, :nxdomain} = UnreachableConnection.write(data)
  end
end
