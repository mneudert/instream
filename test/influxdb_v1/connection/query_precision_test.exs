defmodule Instream.InfluxDBv1.Connection.QueryPrecisionTest do
  use ExUnit.Case, async: true

  @moduletag :"influxdb_exclude_2.x"

  alias Instream.TestHelpers.TestConnection

  setup_all do
    TestConnection.write([
      %{
        measurement: "precision_test",
        fields: %{foo: "bar"}
      }
    ])
  end

  test "integer precisions" do
    precisions = [
      {:hour, 6},
      {:minute, 8},
      {:second, 10},
      {:millisecond, 13},
      {:microsecond, 16},
      {:nanosecond, 19}
    ]

    for {precision, timelen} <- precisions do
      %{results: [%{series: [%{values: [[time, _]]}]}]} =
        TestConnection.query("SELECT * FROM precision_test", precision: precision)

      assert ^timelen =
               time
               |> Kernel.to_string()
               |> String.length()
    end
  end

  test "rfc3339 precision" do
    %{results: [%{series: [%{values: [[time, _]]}]}]} =
      TestConnection.query("SELECT * FROM precision_test", precision: :rfc3339)

    assert 20 <= String.length(time)
    assert String.contains?(time, "Z")
  end
end
