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

  def determine_database(%{database: database}, opts) do
    opts[:database] || database
  end

  def determine_database(_, opts), do: opts[:database]

  @doc """
  Creates a writing query object from a single or a list of points.
  """
  @spec query(map | [map], Keyword.t()) :: Query.t()
  def query(points, opts) when is_list(points) do
    point_data = multi_unstruct(points, [])

    query(%{points: point_data}, opts)
  end

  def query(payload, opts) when is_map(payload) do
    %Query{
      payload: maybe_unstruct(payload),
      opts: opts,
      type: :write
    }
  end

  defp maybe_unstruct(%{__struct__: series, fields: fields, tags: tags, timestamp: timestamp}) do
    %{
      points: [
        %{
          measurement: series.__meta__(:measurement),
          fields: Map.from_struct(fields),
          tags: Map.from_struct(tags),
          timestamp: timestamp
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
