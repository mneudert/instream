defmodule Instream.Log.DefaultLoggerTest do
  use ExUnit.Case, async: false

  require Logger

  import ExUnit.CaptureLog

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule LogConnection do
    use Instream.Connection, otp_app: :instream
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "log_write_entry_test"

      tag :t

      field :f
    end
  end

  setup_all do
    Application.put_env(
      :instream,
      LogConnection,
      Keyword.drop(DefaultConnection.config(), [:loggers])
    )
  end

  test "logging ping request" do
    log =
      capture_log(fn ->
        :pong = LogConnection.ping()

        Logger.flush()
      end)

    assert String.contains?(log, "ping")
    assert String.contains?(log, "pong")

    assert String.contains?(log, LogConnection.config(:host))

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=204")
  end

  test "logging read request" do
    query = "SELECT value FROM empty_measurement"

    log =
      capture_log(fn ->
        _ = LogConnection.query(query, query_language: :influxql)

        Logger.flush()
      end)

    assert String.contains?(log, "query")
    assert String.contains?(log, query)

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=200")
  end

  @tag :"influxdb_exclude_2.0"
  test "logging read request with redacted password" do
    query = ~s(CREATE USER "instream_test" WITH PASSWORD "instream_test")

    log =
      capture_log(fn ->
        _ = LogConnection.query(query, method: :post)

        Logger.flush()
      end)

    assert String.contains?(log, "CREATE USER")
    refute String.contains?(log, ~s(PASSWORD "instream_test"))
  end

  @tag :"influxdb_exclude_2.0"
  test "logging status request" do
    log =
      capture_log(fn ->
        :ok = LogConnection.status()

        Logger.flush()
      end)

    assert String.contains?(log, "status")
    assert String.contains?(log, "ok")

    assert String.contains?(log, LogConnection.config(:host))

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=204")
  end

  test "logging write request" do
    points = [
      %TestSeries{
        tags: %TestSeries.Tags{t: "foo"},
        fields: %TestSeries.Fields{f: "foo"}
      },
      %TestSeries{
        tags: %TestSeries.Tags{t: "bar"},
        fields: %TestSeries.Fields{f: "bar"}
      }
    ]

    log =
      capture_log(fn ->
        :ok = LogConnection.write(points)

        Logger.flush()
      end)

    assert String.contains?(log, "write")
    assert String.contains?(log, "#{length(points)} points")

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=0")
  end

  describe "passing [log: false]" do
    @tag :"influxdb_exclude_2.0"
    test "ping request" do
      assert "" =
               capture_log(fn ->
                 :pong = LogConnection.ping(log: false)

                 Logger.flush()
               end)
    end

    test "read request" do
      assert "" =
               capture_log(fn ->
                 query = "SELECT value FROM empty_measurement"
                 _ = LogConnection.query(query, query_language: :influxql, log: false)

                 Logger.flush()
               end)
    end
  end
end
