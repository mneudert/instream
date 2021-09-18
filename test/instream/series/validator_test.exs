defmodule Instream.Series.ValidatorTest do
  use ExUnit.Case, async: true

  test "field and tag with same name raises" do
    assert_raise ArgumentError, ~r/same name.+conflicting_name/, fn ->
      defmodule FieldTagSameName do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :conflicting_name
          tag :conflicting_name
        end
      end
    end
  end

  test "forbidden field :_field raises" do
    assert_raise ArgumentError, ~r/forbidden field.+_field/, fn ->
      defmodule ForbiddenFieldField do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :_field
        end
      end
    end
  end

  test "forbidden field :_measurement raises" do
    assert_raise ArgumentError, ~r/forbidden field.+_measurement/, fn ->
      defmodule ForbiddenMeasurementField do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :_measurement
        end
      end
    end
  end

  test "forbidden field :time raises" do
    assert_raise ArgumentError, ~r/forbidden field.+time/, fn ->
      defmodule ForbiddenTimeField do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :time
        end
      end
    end
  end

  test "forbidden tag :_field raises" do
    assert_raise ArgumentError, ~r/forbidden tag.+_field/, fn ->
      defmodule ForbiddenFieldTag do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :satisfy_definition
          tag :_field
        end
      end
    end
  end

  test "forbidden tag :_measurement raises" do
    assert_raise ArgumentError, ~r/forbidden tag.+_measurement/, fn ->
      defmodule ForbiddenMeasurementTag do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :satisfy_definition
          tag :_measurement
        end
      end
    end
  end

  test "forbidden tag :time raises" do
    assert_raise ArgumentError, ~r/forbidden tag.+time/, fn ->
      defmodule ForbiddenTimeTag do
        use Instream.Series

        series do
          measurement "satisfy_definition_rules"

          field :satisfy_definition
          tag :time
        end
      end
    end
  end

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

        series do
        end
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
