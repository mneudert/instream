defmodule Instream.Data.Write do
  @moduledoc false

  alias Instream.Query

  @doc """
  Determines the proper database to write points to.

  Later usage depends on the writer.
  """
  @spec determine_database(map | [map], Keyword.t()) :: String.t() | nil
  def determine_database([point | _], opts) do
    determine_database(point, opts)
  end

  def determine_database(%{__struct__: series}, opts) do
    opts[:database] || series.__meta__(:database)
  end

  def determine_database(%{database: database}, opts) do
    opts[:database] || database
  end

  def determine_database(_, opts), do: opts[:database]

  @doc """
  Creates a writing query object from a single or a list of points.
  """
  @spec query(map | [map], Keyword.t()) :: Query.t()
  def query([point | points], opts) do
    query = query(point, opts)
    add_points = multi_unstruct(points, [])

    joined = [hd(query.payload.points) | add_points]

    %{query | payload: %{query.payload | points: joined}}
  end

  def query(payload, opts) when is_map(payload) do
    %Query{
      payload: maybe_unstruct(payload),
      opts: opts,
      type: :write
    }
  end

  defp maybe_unstruct(%{__struct__: series} = payload) do
    %{
      points: [
        %{
          measurement: series.__meta__(:measurement),
          fields: Map.from_struct(payload.fields),
          tags: Map.from_struct(payload.tags),
          timestamp: payload.timestamp
        }
      ]
    }
  end

  defp maybe_unstruct(payload), do: payload

  defp multi_unstruct([], acc), do: Enum.reverse(acc)

  defp multi_unstruct([point | points], acc) do
    [add_point] =
      point
      |> maybe_unstruct()
      |> Map.get(:points)

    multi_unstruct(points, [add_point | acc])
  end
end
