defmodule Instream.Response do
  @moduledoc """
  Response handling module.
  """

  @doc """
  Maybe parses a response based on the requested result type.
  """
  @spec maybe_parse(Instream.Writer.response, Keyword.t) :: any
  def maybe_parse({ _, _, "" }, _), do: :ok

  def maybe_parse({ status, headers, response }, opts)
      when 300 <= status
  do
    case is_json?(headers) do
      true  -> maybe_decode_json(response, opts)
      false -> maybe_wrap_error(response, opts)
    end
  end

  def maybe_parse({ _, headers, response }, opts) do
    case is_json?(headers) do
      true  -> maybe_decode_json(response, opts)
      false -> response
    end
  end


  defp is_json?([]), do: false

  defp is_json?([{ header, val } | headers ]) do
    if "content-type" == String.downcase(header) do
      String.contains?(val, "json")
    else
      is_json?(headers)
    end
  end


  defp maybe_decode_json(response, opts) do
    case opts[:result_as] do
      :raw -> response
      _    -> response |> Poison.decode!(keys: :atoms)
    end
  end

  defp maybe_wrap_error(error, opts) do
    case opts[:result_as] do
      :raw -> error
      _    -> %{ error: error }
    end
  end
end
