defmodule Instream.Connection.ResponseParserV2 do
  @moduledoc false

  alias Instream.Connection.JSON
  alias Instream.Decoder.CSV
  alias Instream.HTTPClient

  @doc """
  Parses a response.
  """
  @spec maybe_parse(HTTPClient.response(), module, Keyword.t()) :: any
  def maybe_parse({:error, _} = error, _, _), do: error
  def maybe_parse({:ok, _, _, ""}, _, _), do: :ok

  def maybe_parse({:ok, status, _, body}, conn, opts)
      when 300 <= status do
    maybe_decode_json(body, conn, opts)
  end

  def maybe_parse({:ok, _, headers, body}, conn, opts) do
    cond do
      is_csv?(headers) -> maybe_decode_csv(body, opts)
      is_json?(headers) -> maybe_decode_json(body, conn, opts)
      true -> body
    end
  end

  defp is_csv?([]), do: false

  defp is_csv?([{header, val} | headers]) do
    if "content-type" == String.downcase(header) do
      String.contains?(val, "csv")
    else
      is_csv?(headers)
    end
  end

  defp is_json?([]), do: false

  defp is_json?([{header, val} | headers]) do
    if "content-type" == String.downcase(header) do
      String.contains?(val, "json")
    else
      is_json?(headers)
    end
  end

  defp maybe_decode_csv(response, opts) do
    case opts[:result_as] do
      :raw -> response
      _ -> CSV.parse(response)
    end
  end

  defp maybe_decode_json(response, conn, opts) do
    case opts[:result_as] do
      :csv -> response
      :raw -> response
      _ -> JSON.decode(response, conn)
    end
  end
end
