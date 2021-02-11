defmodule Instream.Data.Write do
  @moduledoc false

  alias Instream.Query

  @doc """
  Creates a writing query object from a single or a list of points.
  """
  @spec query(map | [map], Keyword.t()) :: Query.t()
  def query(points, opts) when is_list(points) do
    %Query{
      payload: Enum.map(points, &maybe_unstruct/1),
      opts: opts
    }
  end

  def query(point, opts) when is_map(point) do
    %Query{
      payload: [maybe_unstruct(point)],
      opts: opts
    }
  end

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
