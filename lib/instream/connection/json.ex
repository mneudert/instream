defmodule Instream.Connection.JSON do
  @moduledoc false

  @doc """
  Decodes a JSON value.
  """
  @spec decode(term, module) :: term
  def decode(value, conn) do
    {json_mod, json_fun, json_extra_args} = decoder(conn)

    apply(json_mod, json_fun, [value | json_extra_args])
  end

  @doc """
  Encodes a value to JSON.
  """
  @spec encode(term, module) :: term
  def encode(value, conn) do
    {json_mod, json_fun, json_extra_args} = encoder(conn)

    apply(json_mod, json_fun, [value | json_extra_args])
  end

  defp decoder(conn) do
    :json_decoder
    |> conn.config()
    |> convert_to_mfargs(:decode!)
  end

  defp encoder(conn) do
    :json_encoder
    |> conn.config()
    |> convert_to_mfargs(:encode!)
  end

  defp convert_to_mfargs({_, _, _} = mfargs, _), do: mfargs
  defp convert_to_mfargs({module, function}, _), do: {module, function, []}
  defp convert_to_mfargs(module, function), do: {module, function, []}
end
