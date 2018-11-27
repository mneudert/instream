defmodule Instream.Connection.JSON do
  @moduledoc false

  @default_decoder {Poison, :decode!, [[keys: :atoms]]}

  @doc """
  Returns the JSON decoder for a connection.
  """
  @spec decoder(module) :: {module, atom, [term]}
  def decoder(conn) do
    conn.config()
    |> Keyword.get(:json_decoder, @default_decoder)
    |> convert_to_mfa(:decode!)
  end

  defp convert_to_mfa({_, _, _} = mfa, _), do: mfa
  defp convert_to_mfa(module, function), do: {module, function, []}
end
