defmodule Instream.Data.Write do
  @moduledoc false

  @doc """
  Prepares a list of points for writing.
  """
  @spec prepare(map | [map]) :: [map]
  def prepare(points) when is_list(points), do: Enum.map(points, &maybe_unstruct/1)
  def prepare(point) when is_map(point), do: [maybe_unstruct(point)]

  defp maybe_unstruct(%{__struct__: series, fields: fields, tags: tags, timestamp: timestamp}) do
    %{
      measurement: series.__meta__(:measurement),
      fields: Map.from_struct(fields),
      tags: Map.from_struct(tags),
      timestamp: timestamp
    }
  end

  defp maybe_unstruct(point), do: point
end
