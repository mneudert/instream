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
      bucket "test_series_bucket"
      database "test_series_database"
      org "test_series_org"

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
    assert TestSeries.__meta__(:bucket) == "test_series_bucket"
    assert TestSeries.__meta__(:database) == "test_series_database"
    assert TestSeries.__meta__(:org) == "test_series_org"

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
    bucket = "test_series_bucket"
    database = "test_series_database"
    org = "test_series_org"

    measurement = "test_series_measurement"

    defmodule ClosureDefinition do
      use Instream.Series

      series do
        fn_bucket = fn -> "test_series_bucket" end
        fn_database = fn -> "test_series_database" end
        fn_org = fn -> "test_series_org" end

        fn_measurement = fn -> "test_series_measurement" end

        bucket fn_bucket.()
        database fn_database.()
        org fn_org.()

        measurement fn_measurement.()

        field :satisfy_definition_rules
      end
    end

    defmodule ExternalDefinition do
      use Instream.Series

      defmodule ExternalDefinitionProvider do
        def bucket, do: "test_series_bucket"
        def database, do: "test_series_database"
        def org, do: "test_series_org"

        def measurement, do: "test_series_measurement"
      end

      series do
        bucket ExternalDefinitionProvider.bucket()
        database ExternalDefinitionProvider.database()
        org ExternalDefinitionProvider.org()

        measurement ExternalDefinitionProvider.measurement()

        field :satisfy_definition_rules
      end
    end

    defmodule InterpolatedDefinition do
      use Instream.Series

      series do
        bucket "#{Mix.env()}_series_bucket"
        database "#{Mix.env()}_series_database"
        org "#{Mix.env()}_series_org"

        measurement "#{Mix.env()}_series_measurement"

        field :satisfy_definition_rules
      end
    end

    assert ^bucket = ClosureDefinition.__meta__(:bucket)
    assert ^database = ClosureDefinition.__meta__(:database)
    assert ^measurement = ClosureDefinition.__meta__(:measurement)
    assert ^org = ClosureDefinition.__meta__(:org)

    assert ^bucket = ExternalDefinition.__meta__(:bucket)
    assert ^database = ExternalDefinition.__meta__(:database)
    assert ^measurement = ExternalDefinition.__meta__(:measurement)
    assert ^org = ExternalDefinition.__meta__(:org)

    assert ^bucket = InterpolatedDefinition.__meta__(:bucket)
    assert ^database = InterpolatedDefinition.__meta__(:database)
    assert ^measurement = InterpolatedDefinition.__meta__(:measurement)
    assert ^org = InterpolatedDefinition.__meta__(:org)
  end
end
