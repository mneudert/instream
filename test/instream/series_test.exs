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

      tag :host
      tag :core

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
    assert TestSeries.__meta__(:measurement) == :cpu_load
    assert TestSeries.__meta__(:tags)        == [ :host, :core ]
  end
end
