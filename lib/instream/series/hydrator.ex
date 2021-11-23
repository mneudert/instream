defmodule Instream.Series.Hydrator do
  @moduledoc false

  alias Instream.Decoder.RFC3339

  @doc """
  Converts a plain map into a series definition struct.

  Keys not defined in the series are silently dropped.
  """
  @spec from_map(module, map) :: struct
  def from_map(series, data) do
    data_fields = Map.take(data, series.__meta__(:fields))
    data_tags = Map.take(data, series.__meta__(:tags))

    struct(series, %{
      fields: struct(Module.safe_concat(series, Fields), data_fields),
      tags: struct(Module.safe_concat(series, Tags), data_tags),
      timestamp: convert_to_timestamp(data[:time] || data[:timestamp])
    })
  end

  @doc """
  Converts a query result map into a list of series definition structs.

  Keys not defined in the series are silently dropped.
  """
  @spec from_result(module, map | [map]) :: [struct]
  def from_result(series, %{
        results: [%{series: [%{values: result_values, columns: columns} = data]}]
      }) do
    # optional :tags set in InfluxQL "GROUP BY" results
    tags = Map.get(data, :tags, %{})

    Enum.map(result_values, fn values ->
      mapped_values =
        columns
        |> Enum.zip(values)
        |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)

      from_map(series, Map.merge(tags, mapped_values))
    end)
  end

  def from_result(series, rows) when is_list(rows) do
    Enum.map(rows, fn row ->
      field_key = String.to_atom(row["_field"])
      field_value = row["_value"]
      timestamp = row["_time"]

      data =
        row
        |> Map.drop(["_field", "_measurement", "_start", "_stop", "_time", "_value", "table"])
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
        |> Map.put(field_key, field_value)
        |> Map.put(:time, timestamp)

      from_map(series, data)
    end)
  end

  defp convert_to_timestamp(time) when is_integer(time), do: time
  defp convert_to_timestamp(time) when is_binary(time), do: RFC3339.to_nanosecond(time)
  defp convert_to_timestamp(_), do: nil
end
