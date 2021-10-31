defmodule Instream.Connection.ResponseParserV1 do
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

  def maybe_parse({:ok, status, headers, body}, conn, opts)
      when 300 <= status do
    if content_type_contains?("json", headers) do
      maybe_decode_json(body, conn, opts)
    else
      maybe_wrap_error(body, opts)
    end
  end

  def maybe_parse({:ok, _, headers, body}, conn, opts) do
    cond do
      content_type_contains?("csv", headers) -> maybe_decode_csv(body, opts)
      content_type_contains?("json", headers) -> maybe_decode_json(body, conn, opts)
      true -> body
    end
  end

  defp content_type_contains?(type_part, headers) do
    case HTTPClient.Headers.find("content-type", headers) do
      nil -> false
      val -> String.contains?(val, type_part)
    end
  end

  defp maybe_decode_csv(response, opts) do
    case opts[:result_as] do
      :csv -> CSV.parse(response)
      _ -> response
    end
  end

  defp maybe_decode_json(response, conn, opts) do
    case opts[:result_as] do
      :raw -> response
      _ -> JSON.decode(response, conn)
    end
  end

  defp maybe_wrap_error(error, opts) do
    error = String.trim(error)

    case opts[:result_as] do
      :raw -> error
      _ -> %{error: error}
    end
  end
end
