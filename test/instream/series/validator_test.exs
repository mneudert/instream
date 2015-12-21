defmodule Instream.Series.ValidatorTest do
  use ExUnit.Case, async: true

  test "missing measurement raises" do
    assert_raise ArgumentError, ~r/missing measurement/, fn ->
      defmodule MissingMeasurement do
        use Instream.Series

        series do end
      end
    end
  end

  test "missing series raises" do
    assert_raise ArgumentError, ~r/missing series/, fn ->
      defmodule MissingSeries do
        use Instream.Series
      end
    end
  end
end
