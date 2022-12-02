defmodule Instream.Log.DefaultLoggerTest do
  use ExUnit.Case, async: false

  require Logger

  import ExUnit.CaptureLog

  alias Instream.Connection.JSON
  alias Instream.TestHelpers.TestConnection

  defmodule LogConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        init: {__MODULE__, :init}
      ]

    def init(conn) do
      config = Keyword.drop(TestConnection.config(), [:loggers])

      Application.put_env(:instream, conn, config)
    end
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "log_write_entry_test"

      tag :t

      field :f
    end
  end

  test "logging ping request" do
    start_supervised!(LogConnection)

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
    start_supervised!(LogConnection)

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

  @tag :"influxdb_exclude_2.x"
  test "logging read request with redacted password" do
    start_supervised!(LogConnection)

    auth = TestConnection.config(:auth)
    query = ~s(CREATE USER "#{auth[:username]}" WITH PASSWORD "#{auth[:password]}")

    log =
      capture_log(fn ->
        _ = LogConnection.query(query, method: :post)

        Logger.flush()
      end)

    assert String.contains?(log, "CREATE USER")
    refute String.contains?(log, ~s(PASSWORD "#{auth[:password]}"))
  end

  @tag :"influxdb_exclude_2.x"
  test "logging status request" do
    start_supervised!(LogConnection)

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
    start_supervised!(LogConnection)

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
    assert String.contains?(log, "response_status=204")
  end

  @tag :"influxdb_include_2.x"
  test "logging delete request" do
    start_supervised!(LogConnection)

    predicate = %{
      predicate: "filled=\"filled_tag\"",
      start: DateTime.to_iso8601(~U[2021-01-01T00:00:00Z]),
      stop: DateTime.to_iso8601(DateTime.utc_now())
    }

    log =
      capture_log(fn ->
        :ok = LogConnection.delete(predicate)

        Logger.flush()
      end)

    assert String.contains?(log, "delete")
    assert String.contains?(log, "#{JSON.encode(predicate, LogConnection)} predicate")

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=204")
  end

  describe "passing [log: false]" do
    @tag :"influxdb_exclude_2.x"
    test "ping request" do
      start_supervised!(LogConnection)

      assert "" =
               capture_log(fn ->
                 :pong = LogConnection.ping(log: false)

                 Logger.flush()
               end)
    end

    test "read request" do
      start_supervised!(LogConnection)

      assert "" =
               capture_log(fn ->
                 query = "SELECT value FROM empty_measurement"
                 _ = LogConnection.query(query, query_language: :influxql, log: false)

                 Logger.flush()
               end)
    end
  end
end
