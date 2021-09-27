defmodule Instream.SeriesTest do
  use ExUnit.Case, async: true

  defmodule DefaultValueSeries do
    use Instream.Series

    series do
      measurement "hosts"

      tag :host, default: "www"
      tag :host_id, default: 1
      tag :cpu

      field :high
      field :low, default: 25
    end
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "cpu_load"

      tag :host
      tag :core

      field :value
    end
  end

  test "series default values" do
    assert %{tags: %{host: "www", host_id: 1, cpu: nil}, fields: %{high: nil, low: 25}} =
             %DefaultValueSeries{}
  end

  test "series metadata" do
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

    assert ^mod = struct.__struct__
    assert ^mod_fields = struct.fields.__struct__
    assert ^mod_tags = struct.tags.__struct__

    assert ^fields = TestSeries.__meta__(:fields)
    assert ^tags = TestSeries.__meta__(:tags)
  end

  test "extended series definition" do
    measurement = "test_series_measurement"

    defmodule ClosureDefinition do
      use Instream.Series, skip_validation: true

      series do
        fn_measurement = fn -> "test_series_measurement" end

        measurement fn_measurement.()
      end
    end

    defmodule ExternalDefinition do
      use Instream.Series, skip_validation: true

      defmodule ExternalDefinitionProvider do
        def measurement, do: "test_series_measurement"
      end

      series do
        measurement ExternalDefinitionProvider.measurement()
      end
    end

    defmodule InterpolatedDefinition do
      use Instream.Series, skip_validation: true

      series do
        measurement "#{Mix.env()}_series_measurement"
      end
    end

    assert ^measurement = ClosureDefinition.__meta__(:measurement)
    assert ^measurement = ExternalDefinition.__meta__(:measurement)
    assert ^measurement = InterpolatedDefinition.__meta__(:measurement)
  end
end
