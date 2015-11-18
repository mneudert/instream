defmodule Instream.Data.Write do
  @moduledoc """
  Database write query helper.
  """

  alias Instream.Query

  @doc """
  Creates a writing query object from a list of raw queries.
  """
  @spec query(map | [map], Keyword.t) :: Query.t
  def query(payload, opts \\ [])
  def query(payload, opts) when is_map(payload) do
    %Query{
      payload: payload |> maybe_unstruct(),
      opts:    opts,
      type:    :write
    }
  end
  def query(payload, opts) when is_map(payload) do
    query(payload, [])
  end
  def query([first | rest], opts) when is_map(first) do
    query(rest, opts, query(first, opts))
  end

  defp query([], opts, query = %Query{}) do
    q = %Query{ query | payload: %{ query.payload | points: Enum.reverse(query.payload.points)}} 
    query(q.payload, opts)
  end
  defp query([first | rest], opts, acc = %Query{payload: %{points: points}}) when is_map(first) and is_list(points) do
    joined = (first |> maybe_unstruct |> Map.get(:points)) ++ points
    acc = %Query{ acc | payload: %{ acc.payload | points: joined}}
    query(rest, opts, acc)
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
end
