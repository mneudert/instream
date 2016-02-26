defmodule Instream.SeriesTest do
  use ExUnit.Case, async: true


  defmodule DefaultValueSeries do
    use Instream.Series

    series do
      measurement "hosts"

      tag :host,    default: "www"
      tag :host_id, default: 1
      tag :cpu

      field :high
      field :low, default: 25
    end
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      database    "test_database"
      measurement "cpu_load"

      tag :host
      tag :core

      field :value
    end
  end


  test "series default values" do
    default = %DefaultValueSeries{}

    assert default.tags.host    == "www"
    assert default.tags.host_id == 1
    assert default.tags.cpu     == nil

    assert default.fields.high == nil
    assert default.fields.low  == 25
  end


  test "series metadata" do
    assert TestSeries.__meta__(:database)    == "test_database"
    assert TestSeries.__meta__(:fields)      == [ :value ]
    assert TestSeries.__meta__(:measurement) == "cpu_load"
    assert TestSeries.__meta__(:tags)        == [ :core, :host ]
  end


  test "series struct" do
    mod        = TestSeries
    mod_fields = TestSeries.Fields
    mod_tags   = TestSeries.Tags

    struct = %TestSeries{}
    fields = struct.fields |> Map.from_struct() |> Map.keys
    tags   = struct.tags |> Map.from_struct() |> Map.keys

    assert mod        == struct.__struct__
    assert mod_fields == struct.fields.__struct__
    assert mod_tags   == struct.tags.__struct__

    assert fields == TestSeries.__meta__(:fields)
    assert tags   == TestSeries.__meta__(:tags)
  end
end
