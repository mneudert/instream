defmodule Instream.Response do
  @moduledoc """
  Response parser.
  """

  alias Instream.Connection.JSON

  @type t :: {:error, term} | {status :: pos_integer, headers :: list, body :: String.t()}

  @doc """
  Maybe parses a response based on the requested result type.
  """
  @spec maybe_parse(t, module, Keyword.t()) :: any
  def maybe_parse({:error, _} = error, _, _), do: error
  def maybe_parse({_, _, ""}, _, _), do: :ok

  def maybe_parse({status, headers, body}, conn, opts)
      when 300 <= status do
    if :v2 === conn.config([:version]) || is_json?(headers) do
      maybe_decode_json(body, conn, opts)
    else
      maybe_wrap_error(body, opts)
    end
  end

  def maybe_parse({_, headers, body}, conn, opts) do
    if :v2 === conn.config([:version]) || is_json?(headers) do
      maybe_decode_json(body, conn, opts)
    else
      body
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

  defp maybe_decode_json(response, conn, opts) do
    case opts[:result_as] do
      :csv ->
        response

      :raw ->
        response

      _ ->
        {json_mod, json_fun, json_extra_args} = JSON.decoder(conn)

        apply(json_mod, json_fun, [response | json_extra_args])
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
