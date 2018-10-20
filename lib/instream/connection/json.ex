defmodule Instream.Connection.JSON do
  @moduledoc false

  @doc """
  Returns the JSON decoder for a connection.
  """
  @spec decoder(module) :: module
  def decoder(conn) do
    Keyword.get(conn.config(), :json_decoder, Poison)
  end
end
