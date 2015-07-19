defmodule Instream.SeriesTest do
  use ExUnit.Case, async: true


  defmodule EmptySeries do
    use Instream.Series

    series do end
  end

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement :cpu_load

      tag :core
      tag :host

      field :value
    end
  end


  test "series metadata defaults" do
    assert EmptySeries.__meta__(:fields)      == []
    assert EmptySeries.__meta__(:measurement) == nil
    assert EmptySeries.__meta__(:tags)        == []
  end

  test "series metadata" do
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
