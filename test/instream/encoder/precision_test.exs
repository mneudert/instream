defmodule Instream.Encoder.PrecisionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  setup_all do
    DefaultConnection.write(%{
      database: "test_database",
      points: [
        %{
          measurement: "precision_test",
          fields: %{foo: "bar"}
        }
      ]
    })
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

  test "rfc3339 precision" do
    %{results: [%{series: [%{values: [[time, _]]}]}]} =
      DefaultConnection.query("SELECT * FROM precision_test",
        database: "test_database",
        precision: :rfc3339
      )

    resultlen =
      time
      |> Kernel.to_string()
      |> String.length()

    assert resultlen >= 20
    assert String.contains?(time, "Z")
  end
end
