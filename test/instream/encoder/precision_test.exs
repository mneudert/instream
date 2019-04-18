defmodule Instream.Encoder.PrecisionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  test "available precisions are valid" do
    assert :ok ==
             %{
               database: "test_database",
               points: [
                 %{
                   measurement: "precision_test",
                   fields: %{foo: "bar"}
                 }
               ]
             }
             |> DefaultConnection.write()

    :timer.sleep(250)

    [
      {:hour, 6},
      {:minute, 8},
      {:second, 10},
      {:millisecond, 13},
      {:microsecond, 16},
      {:nanosecond, 19},
      {:rfc3339, 30}
    ]
    |> Enum.each(fn {precision, timelen} ->
      %{results: [%{series: [%{values: [[time, _]]}]}]} =
        DefaultConnection.query("SELECT * FROM precision_test",
          database: "test_database",
          precision: precision
        )

      resultlen =
        time
        |> Kernel.to_string()
        |> String.length()

      assert resultlen == timelen
    end)
  end
end
