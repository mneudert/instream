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

  describe "forbiddent values raise" do
    test "field :_field" do
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

    test "field :_measurement" do
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

    test "field :time" do
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

    test "tag :_field" do
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

    test "tag :_measurement" do
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

    test "tag :time" do
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
  end

  describe "missing values raise" do
    test "fields" do
      assert_raise ArgumentError, ~r/no fields/, fn ->
        defmodule MissingFields do
          use Instream.Series

          series do
            measurement "satisfy_definition_rules"
          end
        end
      end
    end

    test "measurement" do
      assert_raise ArgumentError, ~r/missing measurement/, fn ->
        defmodule MissingMeasurement do
          use Instream.Series

          series do
          end
        end
      end
    end

    test "series" do
      assert_raise ArgumentError, ~r/missing series/, fn ->
        defmodule MissingSeries do
          use Instream.Series
        end
      end
    end
  end

  test "allow deactivating validation" do
    defmodule UnvalidatedSeries do
      use Instream.Series, skip_validation: true

      series do
        measurement "satisfy_definition_rules"

        field :conflicting_name
        tag :conflicting_name
      end
    end

    assert UnvalidatedSeries.__meta__(:fields) == UnvalidatedSeries.__meta__(:tags)
  end
end
