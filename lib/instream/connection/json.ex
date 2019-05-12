defmodule Instream.Connection.JSON do
  @moduledoc false

  @default_decoder {Poison, :decode!, [[keys: :atoms]]}
  @default_encoder {Poison, :encode!, []}

  @doc """
  Returns the JSON decoder for a connection.
  """
  @spec decoder(module) :: {module, atom, [term]}
  def decoder(conn) do
    conn.config()
    |> Keyword.get(:json_decoder, @default_decoder)
    |> convert_to_mfa(:decode!)
  end

  @doc """
  Returns the JSON encoder for a connection.
  """
  @spec encoder(module) :: {module, atom, [term]}
  def encoder(conn) do
    conn.config()
    |> Keyword.get(:json_encoder, @default_encoder)
    |> convert_to_mfa(:encode!)
  end

  defp convert_to_mfa({_, _, _} = mfa, _), do: mfa
  defp convert_to_mfa({module, function}, _), do: {module, function, []}
  defp convert_to_mfa(module, function), do: {module, function, []}
end
