defmodule Instream.Data.Write do
  @moduledoc """
  Database write query helper.
  """

  alias Instream.Query

  @doc """
  Creates a writing query object from a raw query string.
  """
  @spec query(map) :: Query.t
  def query(payload) do
    %Query{
      payload: payload |> maybe_unstruct(),
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
end
