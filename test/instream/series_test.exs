defmodule Instream.SeriesTest do
  use ExUnit.Case, async: true

  defmodule DefaultValueSeries do
    use Instream.Series

    series do
      measurement("hosts")

      tag(:host, default: "www")
      tag(:host_id, default: 1)
      tag(:cpu)

      field(:high)
      field(:low, default: 25)
    end
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      database("test_series_database")
      measurement("cpu_load")

      tag(:host)
      tag(:core)

      field(:value)
    end
  end

  test "series default values" do
    default = %DefaultValueSeries{}

    assert default.tags.host == "www"
    assert default.tags.host_id == 1
    assert default.tags.cpu == nil

    assert default.fields.high == nil
    assert default.fields.low == 25
  end

  test "series metadata" do
    assert TestSeries.__meta__(:database) == "test_series_database"
    assert TestSeries.__meta__(:fields) == [:value]
    assert TestSeries.__meta__(:measurement) == "cpu_load"
    assert TestSeries.__meta__(:tags) == [:core, :host]
  end

  test "series struct" do
    mod = TestSeries
    mod_fields = TestSeries.Fields
    mod_tags = TestSeries.Tags

    struct = %TestSeries{}
    fields = struct.fields |> Map.from_struct() |> Map.keys()
    tags = struct.tags |> Map.from_struct() |> Map.keys()

    assert mod == struct.__struct__
    assert mod_fields == struct.fields.__struct__
    assert mod_tags == struct.tags.__struct__

    assert fields == TestSeries.__meta__(:fields)
    assert tags == TestSeries.__meta__(:tags)
  end

  test "extended series definition" do
    database = "test_series_database"
    measurement = "test_series_measurement"

    defmodule ClosureDefinition do
      use Instream.Series

      series do
        fn_database = fn -> "test_series_database" end
        fn_measurement = fn -> "test_series_measurement" end

        database(fn_database.())
        measurement(fn_measurement.())

        field(:satisfy_definition_rules)
      end
    end

    defmodule ExternalDefinition do
      use Instream.Series

      defmodule ExternalDefinitionProvider do
        def database, do: "test_series_database"
        def measurement, do: "test_series_measurement"
      end

      series do
        database(ExternalDefinitionProvider.database())
        measurement(ExternalDefinitionProvider.measurement())

        field(:satisfy_definition_rules)
      end
    end

    defmodule InterpolatedDefinition do
      use Instream.Series

      series do
        database("#{Mix.env()}_series_database")
        measurement("#{Mix.env()}_series_measurement")

        field(:satisfy_definition_rules)
      end
    end

    assert database == ClosureDefinition.__meta__(:database)
    assert database == ExternalDefinition.__meta__(:database)
    assert database == InterpolatedDefinition.__meta__(:database)

    assert measurement == ClosureDefinition.__meta__(:measurement)
    assert measurement == ExternalDefinition.__meta__(:measurement)
    assert measurement == InterpolatedDefinition.__meta__(:measurement)
  end
end
