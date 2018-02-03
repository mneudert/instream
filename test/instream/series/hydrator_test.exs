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

  test "hydrating from query result" do
    hydrated =
      TestSeries.from_result(%{
        results: [
          %{
            series: [
              %{
                columns: ["time", "value"],
                name: "write_data_async",
                tags: %{foo: "bar"},
                values: [["2015-08-14T21:32:06Z", 200], ["2015-08-14T21:32:07Z", 300]]
              }
            ]
          }
        ]
      })

    [first, second] = hydrated

    assert 200 == first.fields.value
    assert "bar" == first.tags.foo

    assert 300 == second.fields.value
    assert "bar" == second.tags.foo
  end
end
