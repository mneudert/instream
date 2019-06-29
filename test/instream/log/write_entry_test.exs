defmodule Instream.Log.WriteEntryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  defmodule LogConnection do
    use Instream.Connection,
      config: [
        auth: [method: :query, username: "instream_test", password: "instream_test"]
      ]
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      database "test_database"
      measurement "log_write_entry_test"

      tag :t

      field :f
    end
  end

  setup do
    {:ok, _} = start_supervised(LogConnection)
    :ok
  end

  test "logging write requests" do
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

        :timer.sleep(10)
      end)

    assert String.contains?(log, "write")
    assert String.contains?(log, "#{length(points)} points")

    assert String.contains?(log, "query_time=")
    assert String.contains?(log, "response_status=0")
  end
end
