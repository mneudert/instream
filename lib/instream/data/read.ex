defmodule Instream.Data.Read do
  @moduledoc """
  Database read query helper.
  """

  alias Instream.Query

  @doc """
  Creates a reading query object from a raw query string.
  """
  @spec query(query_str :: String.t) :: Query.t
  def query(query_str) do
    %Query{
      payload: query_str,
      type:    :read
    }
  end
end
