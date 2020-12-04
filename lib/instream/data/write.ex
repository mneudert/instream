defmodule Instream.Data.Write do
  @moduledoc false

  alias Instream.Query

  @doc """
  Creates a writing query object from a single or a list of points.
  """
  @spec query(map | [map], Keyword.t()) :: Query.t()
  def query(points, opts) when is_list(points) do
    %Query{
      payload: %{
        points: Enum.map(points, &maybe_unstruct/1)
      },
      opts: opts,
      type: :write
    }
  end

  def query(%{__struct__: _} = point, opts) do
    %Query{
      payload: %{
        points: [maybe_unstruct(point)]
      },
      opts: opts,
      type: :write
    }
  end

  def query(%{points: _} = payload, opts) do
    %Query{
      payload: payload,
      opts: opts,
      type: :write
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
