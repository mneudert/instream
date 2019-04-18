defmodule Instream.Deprecations.EncoderPrecisionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Instream.Encoder.Precision

  test "deprecated precision unit warns" do
    [
      {:hours, :hour},
      {:minutes, :minute},
      {:seconds, :second},
      {:milliseconds, :millisecond},
      {:microseconds, :microsecond},
      {:nanoseconds, :nanosecond},
      {:milli_seconds, :millisecond},
      {:micro_seconds, :microsecond},
      {:nano_seconds, :nanosecond}
    ]
    |> Enum.each(fn {old, new} ->
      check = Regex.compile!("Deprecated.+" <> inspect(old) <> ".+" <> inspect(new))
      log = capture_log(fn -> Precision.encode(old) end)

      assert Regex.match?(check, log)
    end)
  end
end
