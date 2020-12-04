defmodule Instream.Encoder.PrecisionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  setup_all do
    DefaultConnection.write([
      %{
        measurement: "precision_test",
        fields: %{foo: "bar"}
      }
    ])
  end

  test "integer precisions" do
    [
      {:hour, 6},
      {:minute, 8},
      {:second, 10},
      {:millisecond, 13},
      {:microsecond, 16},
      {:nanosecond, 19}
    ]
    |> Enum.each(fn {precision, timelen} ->
      %{results: [%{series: [%{values: [[time, _]]}]}]} =
        DefaultConnection.query("SELECT * FROM precision_test", precision: precision)

      assert ^timelen =
               time
               |> Kernel.to_string()
               |> String.length()
    end)
  end

  test "rfc3339 precision" do
    %{results: [%{series: [%{values: [[time, _]]}]}]} =
      DefaultConnection.query("SELECT * FROM precision_test", precision: :rfc3339)

    assert 20 <=
             time
             |> Kernel.to_string()
             |> String.length()

    assert String.contains?(time, "Z")
  end
end
