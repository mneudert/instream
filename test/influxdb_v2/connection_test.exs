defmodule Instream.InfluxDBv2.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_include_2.x"

  import Mox

  alias Instream.TestHelpers.HTTPClientMock
  alias Instream.TestHelpers.TestConnection

  setup :verify_on_exit!

  defmodule MockConnection do
    use Instream.Connection,
      config: [
        database: "default_database",
        http_client: HTTPClientMock,
        loggers: []
      ]
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "data_write_struct"

      tag :bar
      tag :foo

      field :numeric
      field :boolean
    end
  end

  @tags %{bar: "bar", foo: "foo"}

  test "mismatched InfluxDB version" do
    assert {:error, :version_mismatch} = TestConnection.status()
  end

  test "ping connection" do
    HTTPClientMock
    |> expect(:request, fn :head, _, _, _, _ -> {:ok, 500, []} end)

    assert :error = MockConnection.ping()
    assert :pong = TestConnection.ping()
  end

  test "version connection" do
    HTTPClientMock
    |> expect(:request, fn :head, _, _, _, _ -> {:ok, 204, []} end)

    assert "unknown" == MockConnection.version()
    refute "unknown" == TestConnection.version()
  end

  test "write data" do
    measurement = "write_data"

    :ok =
      TestConnection.write([
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{numeric: 0.66, boolean: true}
        }
      ])

    result =
      TestConnection.query("""
        from(bucket: "#{TestConnection.config(:bucket)}")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "#{measurement}"
        )
        |> last()
      """)

    assert [
             [
               %{
                 "_field" => "boolean",
                 "_measurement" => ^measurement,
                 "_value" => true,
                 "bar" => "bar",
                 "foo" => "foo",
                 "result" => "_result"
               }
             ],
             [
               %{
                 "_field" => "numeric",
                 "_measurement" => ^measurement,
                 "_value" => 0.66,
                 "bar" => "bar",
                 "foo" => "foo",
                 "result" => "_result"
               }
             ]
           ] = result
  end

  test "writing series struct" do
    measurement = TestSeries.__meta__(:measurement)

    :ok =
      %{
        bar: "bar",
        foo: "foo",
        boolean: false,
        numeric: 17
      }
      |> TestSeries.from_map()
      |> TestConnection.write()

    result =
      TestConnection.query("""
        from(bucket: "#{TestConnection.config(:bucket)}")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "#{measurement}"
        )
        |> last()
      """)

    assert [
             [
               %{
                 "_field" => "boolean",
                 "_measurement" => ^measurement,
                 "_value" => false,
                 "bar" => "bar",
                 "foo" => "foo",
                 "result" => "_result"
               }
             ],
             [
               %{
                 "_field" => "numeric",
                 "_measurement" => ^measurement,
                 "_value" => 17,
                 "bar" => "bar",
                 "foo" => "foo",
                 "result" => "_result"
               }
             ]
           ] = result
  end

  test "read using InfluxQL and params" do
    test_field = ~S|string field value, only " need be quoted|
    test_tag = ~S|tag,value,with"commas"|

    :ok =
      TestConnection.write([
        %{
          measurement: "params",
          tags: %{foo: test_tag},
          fields: %{value: test_field}
        }
      ])

    query = "SELECT LAST(value) FROM params WHERE foo = $foo_val"
    params = %{foo_val: test_tag}

    assert %{results: [%{series: [%{name: "params", values: [[_, ^test_field]]}]}]} =
             TestConnection.query(query, query_language: :influxql, params: params)
  end
end
