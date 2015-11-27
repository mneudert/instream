defmodule Instream.Data.Write do
  @moduledoc """
  Database write query helper.
  """

  alias Instream.Query

  @doc """
  Creates a writing query object from a single or a list of points.
  """
  @spec query(map | [map], Keyword.t) :: Query.t
  def query([ point | points ], opts) do
    query      = point |> query(opts)
    add_points = points |> multi_unstruct([])

    joined = [ hd(query.payload.points) | add_points ]

    %{ query | payload: %{ query.payload | points: joined }}
  end

  def query(payload, opts) when is_map(payload)  do
    %Query{
      payload: payload |> maybe_unstruct(),
      opts:    opts,
      type:    :write
    }
  end


  defp maybe_unstruct(%{ __struct__: series } = payload) do
    %{
      database: series.__meta__(:database),
      points:   [
        %{
          measurement: series.__meta__(:measurement),
          fields:      payload.fields |> Map.from_struct(),
          tags:        payload.tags   |> Map.from_struct(),
          timestamp:   payload.timestamp
        }
      ]
    }
  end

  defp maybe_unstruct(payload), do: payload


  defp multi_unstruct([],                 acc), do: acc |> Enum.reverse()
  defp multi_unstruct([ point | points ], acc)  do
    [ add_point ] = point |> maybe_unstruct() |> Map.get(:points)

    points |> multi_unstruct([ add_point | acc ])
  end
end
