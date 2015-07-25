defmodule Instream.Data.Write do
  @moduledoc """
  Database write query helper.
  """

  alias Instream.Query

  @doc """
  Creates a writing query object from a raw query string.
  """
  @spec query(payload :: map) :: Query.t
  def query(payload) do
    %Query{
      payload: payload |> maybe_unstruct() |> Poison.encode!,
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
          tags:        payload.tags |> Map.from_struct()
        }
      ]
    }
  end

  defp maybe_unstruct(payload), do: payload
end
