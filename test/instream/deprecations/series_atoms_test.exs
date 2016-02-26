defmodule Instream.Deprecations.SeriesAtomsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "series database atom" do
    message = capture_io :stderr, fn ->
      defmodule DeprecatedDatabaseAtom do
        use Instream.Series

        series do
          database    :is_an_atom
          measurement "is_a_string"
        end
      end
    end

    assert String.contains?(message, "deprecated")
  end

  test "series measurement atom" do
    message = capture_io :stderr, fn ->
      defmodule DeprecatedMeasurementAtom do
        use Instream.Series

        series do
          database    "is_a_string"
          measurement :is_an_atom
        end
      end
    end

    assert String.contains?(message, "deprecated")
  end
end
