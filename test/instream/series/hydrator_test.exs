defmodule Instream.Series.HydratorTest do
  use ExUnit.Case, async: true

  defmodule TestSeries do
    use Instream.Series

    series do
      measurement "hydrator_test"

      tag :foo, default: "bar"

      field :value, default: 100
    end
  end

  test "hydrating from map" do
    hydrated =
      TestSeries.from_map(%{
        foo: "hydrate_foo",
        value: 666
      })

    assert 666 == hydrated.fields.value
    assert "hydrate_foo" == hydrated.tags.foo
  end

  test "hydrating from map (defaults)" do
    hydrated = TestSeries.from_map(%{})

    assert 100 == hydrated.fields.value
    assert "bar" == hydrated.tags.foo
  end

  test "hydrating from map (unknown keys)" do
    hydrated = TestSeries.from_map(%{unknown: "element"})

    refute Map.has_key?(hydrated, :unknown)
    refute Map.has_key?(hydrated.fields, :unknown)
    refute Map.has_key?(hydrated.tags, :unknown)
  end
end
