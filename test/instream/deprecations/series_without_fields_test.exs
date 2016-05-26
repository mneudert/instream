defmodule Instream.Deprecations.SeriesWithoutFieldsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "without fields" do
    stderr = capture_io :stderr, fn ->
      defmodule WithoutFields do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"
        end
      end
    end

    assert String.contains?(stderr, "without fields")
  end
end
