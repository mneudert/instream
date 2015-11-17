defmodule Instream.Data.Write do
  @moduledoc """
  Database write query helper.
  """

  alias Instream.Query

  @doc """
  Creates a writing query object from a list of raw queries.
  """
  @spec query([Map] | [], Keyword.t, Query.t) :: Query.t
  def query([], opts, query = %Query{}), do: query(query.payload, opts)
  def query([first | rest], opts, acc = %Query{payload: %{points: points}}) when is_map(first) and is_list(points) do
    joined = points ++ (first |> maybe_unstruct |> Map.get(:points))
    acc = %Query{ acc | payload: %{ acc.payload | points: joined}}
    query(rest, opts, acc)
  end
  @spec query([Map], Keyword.t) :: Query.t
  def query([first | rest], opts) when is_map(first), do: query(rest, opts, query(first, opts))
  @doc """
  Creates a writing query object from a raw query string.
  """
  @spec query(Map, Keyword.t) :: Query.t
  def query(payload, opts) when is_map(payload) do
    %Query{
      payload: payload |> maybe_unstruct(),
      opts:    opts,
      type:    :write
    }
  end
  @spec query(Map) :: Query.t
  def query(payload) when is_map(payload), do: query(payload, [])


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
