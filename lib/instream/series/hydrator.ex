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
end
