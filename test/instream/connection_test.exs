defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.DefaultConnectionV2
  alias Instream.TestHelpers.Connections.GuestConnection
  alias Instream.TestHelpers.Connections.UnixSocketConnection

  @database "test_database"
  @tags %{foo: "foo", bar: "bar"}

  defmodule TestSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :value
    end
  end

  @tag :"influxdb_exclude_2.0"
  test "ping connection" do
    assert :pong = DefaultConnection.ping()
  end

  @tag :"influxdb_exclude_2.0"
  test "status connection" do
    assert :ok = DefaultConnection.status()
  end

  @tag :"influxdb_exclude_2.0"
  test "version connection" do
    assert is_binary(DefaultConnection.version())
  end

  @tag :"influxdb_include_2.0"
  test "mismatched InfluxDB version" do
    assert {:error, :version_mismatch} = DefaultConnectionV2.ping()
    assert {:error, :version_mismatch} = DefaultConnectionV2.status()
    assert {:error, :version_mismatch} = DefaultConnectionV2.version()
  end

  test "read from empty measurement" do
    query = "SELECT value FROM empty_measurement"
    result = DefaultConnection.query(query, database: @database)

    assert %{results: _} = result
  end

  test "read using database in query string" do
    query_in = "SELECT value FROM \"#{@database}\".\"autogen\".\"empty_measurement\""
    query_out = "SELECT value FROM empty_measurement"

    result_in = DefaultConnection.query(query_in)
    result_out = DefaultConnection.query(query_out, database: @database)

    assert ^result_in = result_out
  end

  test "read using params" do
    test_field = ~S|string field value, only " need be quoted|
    test_tag = ~S|tag,value,with"commas"|

    :ok =
      DefaultConnection.write(%{
        database: @database,
        points: [
          %{
            measurement: "params",
            tags: %{foo: test_tag},
            fields: %{value: test_field}
          }
        ]
      })

    query = "SELECT value FROM \"#{@database}\".\"autogen\".\"params\" WHERE foo = $foo_val"
    params = %{foo_val: test_tag}

    assert %{results: [%{series: [%{name: "params", values: [[_, ^test_field]]}]}]} =
             DefaultConnection.query(query, params: params)
  end

  @tag :"influxdb_exclude_1.7"
  test "read using flux query" do
    :ok =
      DefaultConnection.write(%{
        database: @database,
        points: [
          %{
            measurement: "flux",
            tags: %{foo: "bar"},
            fields: %{value: 1}
          }
        ]
      })

    query = ~S[
      from(bucket:"test_database/autogen")
      |> range(start: -1h)
      |> filter(fn: (r) => r._measurement == "flux")
    ]

    result = DefaultConnection.query(query, query_language: :flux)

    assert "#datatype," <> _ = result

    assert String.contains?(result, "flux,bar")
    assert String.contains?(result, "_measurement,foo")
  end

  test "write data" do
    measurement = "write_data"

    :ok =
      %{
        database: @database,
        points: [
          %{
            measurement: measurement,
            tags: @tags,
            fields: %{value: 0.66}
          }
        ]
      }
      |> DefaultConnection.write()

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             DefaultConnection.query(
               "SELECT * FROM #{measurement} GROUP BY *",
               database: @database
             )

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  test "writing series struct" do
    :ok =
      %{
        bar: "bar",
        foo: "foo",
        value: 17
      }
      |> TestSeries.from_map()
      |> DefaultConnection.write()

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             DefaultConnection.query(
               "SELECT * FROM data_write_struct GROUP BY *",
               database: @database
             )

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  @tag :"influxdb_include_2.0"
  test "write data without authorization" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: "write_data_privileges",
          fields: %{value: 0.66}
        }
      ]
    }

    assert %{code: "unauthorized", message: "Unauthorized"} = GuestConnection.write(data)
  end

  @tag :"influxdb_exclude_2.0"
  test "write data with missing privileges" do
    data = %{
      database: @database,
      points: [
        %{
          measurement: "write_data_privileges",
          fields: %{value: 0.66}
        }
      ]
    }

    %{error: error} = GuestConnection.write(data)

    assert String.contains?(error, "not authorized")
  end

  @tag :"influxdb_exclude_2.0"
  test "privilege missing" do
    %{error: error} = GuestConnection.query("DROP DATABASE ignore", method: :post)

    assert String.contains?(error, "requires admin privilege")
  end

  @tag :"influxdb_exclude_2.0"
  @tag :unix_socket
  test "unix socket: ping connection" do
    assert :pong = UnixSocketConnection.ping()
  end

  @tag :"influxdb_exclude_2.0"
  @tag :unix_socket
  test "unix socket: status connection" do
    assert :ok = UnixSocketConnection.status()
  end

  @tag :"influxdb_exclude_2.0"
  @tag :unix_socket
  test "unix socket: version connection" do
    assert is_binary(UnixSocketConnection.version())
  end

  @tag :unix_socket
  test "unix socket: read using database in query string" do
    query_in = "SELECT value FROM \"#{@database}\".\"autogen\".\"empty_measurement\""
    query_out = "SELECT value FROM empty_measurement"

    result_in = query_in |> UnixSocketConnection.query()
    result_out = query_out |> UnixSocketConnection.query(database: @database)

    assert ^result_in = result_out
  end
end
