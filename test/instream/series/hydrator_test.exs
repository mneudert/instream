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
        value: 666,
        timestamp: 1_439_587_926_000_000_000
      })

    assert %{
             fields: %{value: 666},
             tags: %{foo: "hydrate_foo"},
             timestamp: 1_439_587_926_000_000_000
           } = hydrated
  end

  test "hydrating from map (defaults)" do
    hydrated = TestSeries.from_map(%{})

    assert %{fields: %{value: 100}, tags: %{foo: "bar"}, timestamp: nil} = hydrated
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
                values: [[1_439_587_926_000_000_000, 200], [1_439_587_927_000_000_000, 300]]
              }
            ]
          }
        ]
      })

    assert [
             %{
               fields: %{value: 200},
               tags: %{foo: "bar"},
               timestamp: 1_439_587_926_000_000_000
             },
             %{
               fields: %{value: 300},
               tags: %{foo: "bar"},
               timestamp: 1_439_587_927_000_000_000
             }
           ] = hydrated
  end
end
