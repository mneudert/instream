defmodule Instream.Response do
  @moduledoc """
  Response handling module.
  """

  @type t :: { :error, term } | { status  :: pos_integer,
                                  headers :: list,
                                  body    :: String.t }


  @doc """
  Maybe parses a response based on the requested result type.
  """
  @spec maybe_parse(t, Keyword.t) :: any
  def maybe_parse({ :error, _ } = error, _), do: error
  def maybe_parse({ _, _, "" },          _), do: :ok

  def maybe_parse({ status, headers, body }, opts)
      when 300 <= status
  do
    case is_json?(headers) do
      true  -> maybe_decode_json(body, opts)
      false -> maybe_wrap_error(body, opts)
    end
  end

  def maybe_parse({ _, headers, body }, opts) do
    case is_json?(headers) do
      true  -> maybe_decode_json(body, opts)
      false -> body
    end
  end

  @doc """
  Parses the response of a ping query.
  """
  @spec parse_ping(any) :: :pong | :error
  def parse_ping({ :ok, 204, _ }), do: :pong
  def parse_ping(_),               do: :error

  @doc """
  Parses the response of a version query.

  Returns "unknown" if the response did not contain a parseable header.
  """
  @spec parse_version(any) :: String.t | :error
  def parse_version({ :ok, 204, headers }) do
    case List.keyfind(headers, "X-Influxdb-Version", 0) do
      { "X-Influxdb-Version", version } -> version

      _ -> "unknown"
    end
  end

  def parse_version(_), do: :error

  @doc """
  Parses the response of a status query.
  """
  @spec parse_status(any) :: :ok | :error
  def parse_status({ :ok, 204, _ }), do: :ok
  def parse_status(_),               do: :error


  # Internal methods

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
    error = error |> String.strip()

    case opts[:result_as] do
      :raw -> error
      _    -> %{ error: error }
    end
  end
end
