defmodule Instream.Series.Hydrator do
  @moduledoc """
  Hydrates series datasets.
  """

  @doc """
  Converts a plain map into a series definition struct.

  Keys not defined in the series are silently dropped.
  """
  @spec from_map(module, map) :: struct
  def from_map(series, data) do
    data_fields = Map.take(data, series.__meta__(:fields))
    data_tags = Map.take(data, series.__meta__(:tags))

    struct(series, %{
      fields: struct(Module.concat(series, Fields), data_fields),
      tags: struct(Module.concat(series, Tags), data_tags)
    })
  end

  @doc """
  Converts a query result map into a list of series definition structs.

  Keys not defined in the series are silently dropped.
  """
  @spec from_result(module, map) :: [struct]
  def from_result(series, %{results: [%{series: [data]}]}) do
    data_tags = Map.get(data, :tags, %{})

    Enum.map(Map.get(data, :values, []), fn values ->
      data_fields =
        data.columns
        |> Enum.zip(values)
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
        |> Enum.into(%{})

      from_map(series, Map.merge(data_tags, data_fields))
    end)
  end
end
