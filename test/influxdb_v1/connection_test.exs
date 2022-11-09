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

  defmodule QueryLanguageConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__.Initializer, :init}
      ]

    defmodule Initializer do
      def init(conn) do
        config =
          Keyword.merge(
            Application.get_env(:instream, TestConnection),
            query_language: :flux
          )

        Application.put_env(:instream, conn, config)
      end
    end
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

    assert "unknown" == MockConnection.version()
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
        from(bucket:"test_database/autogen")
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

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             TestConnection.query("SELECT * FROM #{measurement} GROUP BY *")

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
      |> TestConnection.write()

    assert %{results: [%{series: [%{tags: values_tags, values: value_rows}]}]} =
             TestConnection.query("SELECT * FROM #{TestSeries.__meta__(:measurement)} GROUP BY *")

    assert @tags == values_tags
    assert 0 < length(value_rows)
  end

  describe "query language from connection config" do
    test "use default from config" do
      start_supervised!(QueryLanguageConnection)

      measurement = "default_query_language_config"

      :ok =
        QueryLanguageConnection.write([
          %{
            measurement: measurement,
            fields: %{value: 42}
          }
        ])

      result =
        QueryLanguageConnection.query("""
        from(bucket:"test_database/autogen")
        |> range(start: -5m)
        |> filter(fn: (r) => r._measurement == "#{measurement}")
        |> last()
        """)

      assert [
               %{
                 "_field" => "value",
                 "_measurement" => ^measurement,
                 "_value" => 42,
                 "result" => "_result"
               }
             ] = result
    end

    test "override default config" do
      start_supervised!(QueryLanguageConnection)

      measurement = "default_query_language_override"

      :ok =
        QueryLanguageConnection.write([
          %{
            measurement: measurement,
            fields: %{value: 42}
          }
        ])

      assert %{results: [%{series: [%{name: ^measurement, values: [[_, 42]]}]}]} =
               QueryLanguageConnection.query("SELECT LAST(value) FROM #{measurement}",
                 query_language: :influxql
               )
    end
  end
end
