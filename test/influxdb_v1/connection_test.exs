defmodule Instream.InfluxDBv1.ConnectionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"

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

      field :value
    end
  end

  @tags %{foo: "foo", bar: "bar"}

  test "ping connection" do
    HTTPClientMock
    |> expect(:request, fn :head, _, _, _, _ -> {:ok, 500, []} end)

    assert :error = MockConnection.ping()
    assert :pong = TestConnection.ping()
  end

  test "status connection" do
    HTTPClientMock
    |> expect(:request, fn :head, _, _, _, _ -> {:ok, 500, []} end)

    assert :error = MockConnection.ping()
    assert :ok = TestConnection.status()
  end

  test "version connection" do
    HTTPClientMock
    |> expect(:request, fn :head, _, _, _, _ -> {:ok, 204, []} end)

    assert "unknown" = MockConnection.version()
    refute "unknown" == TestConnection.version()
  end

  test "read using params" do
    test_field = ~S(string field value, only " need be quoted)
    test_tag = ~S(tag,value,with"commas")

    :ok =
      TestConnection.write([
        %{
          measurement: "params",
          tags: %{foo: test_tag},
          fields: %{value: test_field}
        }
      ])

    query = "SELECT value FROM params WHERE foo = $foo_val"
    params = %{foo_val: test_tag}

    assert %{results: [%{series: [%{name: "params", values: [[_, ^test_field]]}]}]} =
             TestConnection.query(query, params: params)
  end

  @tag :"influxdb_include_1.8"
  test "read using flux query" do
    database = TestConnection.config(:database)
    measurement = "flux"

    :ok =
      TestConnection.write([
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{numeric: 0.66, boolean: true}
        }
      ])

    result =
      TestConnection.query(
        """
        from(bucket:"#{database}/autogen")
        |> range(start: -1h)
        |> filter(fn: (r) => r._measurement == "#{measurement}")
        """,
        query_language: :flux
      )

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

  test "write data" do
    measurement = "write_data"

    :ok =
      TestConnection.write([
        %{
          measurement: measurement,
          tags: @tags,
          fields: %{value: 0.66}
        }
      ])

    assert %{results: [%{series: [%{tags: @tags, values: [_ | _]}]}]} =
             TestConnection.query("SELECT * FROM #{measurement} GROUP BY *")
  end

  test "writing series struct" do
    :ok =
      %{
        bar: "bar",
        foo: "foo",
        value: 17
      }
      |> TestSeries.from_map()
      |> TestConnection.write()

    assert %{results: [%{series: [%{tags: @tags, values: [_ | _]}]}]} =
             TestConnection.query("SELECT * FROM #{TestSeries.__meta__(:measurement)} GROUP BY *")
  end
end
