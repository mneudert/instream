defmodule Instream.Series.ValidatorTest do
  use ExUnit.Case, async: true

  test "missing fields raises" do
    assert_raise ArgumentError, ~r/no fields/, fn ->
      defmodule MissingFields do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"
        end
      end
    end
  end

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
