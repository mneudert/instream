defmodule Instream.Data.Read do
  @moduledoc false

  alias Instream.Query

  @doc """
  Creates a reading query object from a raw query string.

  Valid options for read queries are:

  - `:method` - whether to use a "GET" or "POST" request (as atom)
  - `:precision` - see `Instream.Encoder.Precision` for available values
  """
  @spec query(String.t(), Keyword.t()) :: Query.t()
  def query(query_str, opts) do
    %Query{
      payload: query_str,
      opts: opts,
      type: :read
    }
  end
end
