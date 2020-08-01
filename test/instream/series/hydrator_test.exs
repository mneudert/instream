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

  test "hydrating from map", %{test: test} do
    val_field = System.unique_integer()
    val_tag = Atom.to_string(test)

    {val_timestamp, val_datetime} = create_test_time()

    expected = %TestSeries{
      fields: %TestSeries.Fields{value: val_field},
      tags: %TestSeries.Tags{foo: val_tag},
      timestamp: val_timestamp
    }

    assert ^expected =
             TestSeries.from_map(%{
               foo: val_tag,
               value: val_field,
               timestamp: val_timestamp
             })

    assert ^expected =
             TestSeries.from_map(%{
               foo: val_tag,
               value: val_field,
               timestamp: val_datetime
             })
  end

  test "hydrating from map (defaults)" do
    assert %TestSeries{
             fields: %{value: 100},
             tags: %{foo: "bar"},
             timestamp: nil
           } = TestSeries.from_map(%{})
  end

  test "hydrating from map (unknown keys)" do
    hydrated = TestSeries.from_map(%{unknown: "element"})

    refute Map.has_key?(hydrated, :unknown)
    refute Map.has_key?(hydrated.fields, :unknown)
    refute Map.has_key?(hydrated.tags, :unknown)
  end

  test "hydrating from query result", %{test: test} do
    val_field_1 = System.unique_integer()
    val_field_2 = System.unique_integer()
    val_tag = Atom.to_string(test)

    {val_timestamp_1, val_datetime_1} = create_test_time()
    {val_timestamp_2, val_datetime_2} = create_test_time()

    expected = [
      %TestSeries{
        fields: %TestSeries.Fields{value: val_field_1},
        tags: %TestSeries.Tags{foo: val_tag},
        timestamp: val_timestamp_1
      },
      %TestSeries{
        fields: %TestSeries.Fields{value: val_field_2},
        tags: %TestSeries.Tags{foo: val_tag},
        timestamp: val_timestamp_2
      }
    ]

    assert ^expected =
             TestSeries.from_result(%{
               results: [
                 %{
                   series: [
                     %{
                       columns: ["time", "value"],
                       name: "hydrator_test",
                       tags: %{foo: val_tag},
                       values: [[val_timestamp_1, val_field_1], [val_timestamp_2, val_field_2]]
                     }
                   ]
                 }
               ]
             })

    assert ^expected =
             TestSeries.from_result(%{
               results: [
                 %{
                   series: [
                     %{
                       columns: ["time", "value"],
                       name: "hydrator_test",
                       tags: %{foo: val_tag},
                       values: [[val_datetime_1, val_field_1], [val_datetime_2, val_field_2]]
                     }
                   ]
                 }
               ]
             })
  end

  # `DateTime` only supports :microsecond level precisions
  # OTP 21.0 is required for full precision
  if Code.ensure_loaded?(:calendar) && function_exported?(:calendar, :system_time_to_rfc3339, 2) do
    defp create_test_time do
      timestamp = System.unique_integer([:positive])

      {
        timestamp,
        timestamp |> :calendar.system_time_to_rfc3339(unit: :nanosecond) |> Kernel.to_string()
      }
    end
  else
    defp create_test_time do
      timestamp = System.unique_integer([:positive]) * 10_000

      {
        timestamp,
        timestamp |> DateTime.from_unix!(:nanosecond) |> DateTime.to_iso8601()
      }
    end
  end
end
