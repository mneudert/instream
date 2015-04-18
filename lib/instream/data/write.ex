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
      payload: payload |> Poison.encode!,
      type:    :write
    }
  end
end
