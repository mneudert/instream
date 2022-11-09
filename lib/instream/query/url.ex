defmodule Instream.Query.URL do
  @moduledoc false

  @doc """
  Appends a (json encoded) parameter map to a URL.
  """
  @spec append_json_params(String.t(), String.t()) :: String.t()
  def append_json_params(json_params, url), do: append_param(url, "params", json_params)

  @doc """
  Appends a query to a URL.
  """
  @spec append_query(String.t(), String.t()) :: String.t()
  def append_query(url, query), do: append_param(url, "q", query)

  @doc """
  Returns the proper URL for a `:ping` request.
  """
  @spec ping(Keyword.t()) :: String.t()
  def ping(config), do: url(config, "ping")

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(Keyword.t(), Keyword.t()) :: String.t()
  def query(config, opts) do
    case {config[:version], opts[:query_language]} do
      {:v2, :influxql} ->
        config
        |> url("query")
        |> append_param("db", opts[:database] || config[:database])
        |> append_param("epoch", encode_precision(opts[:precision]))

      {:v2, _} ->
        config
        |> url("api/v2/query")
        |> append_param("org", opts[:org] || config[:org])

      {:v1, :flux} ->
        config
        |> url("api/v2/query")
        |> append_param("db", opts[:database] || config[:database])
        |> append_param("epoch", encode_precision(opts[:precision]))
        |> append_param("org", opts[:org] || config[:org])

      {:v1, _} ->
        config
        |> url("query")
        |> append_param("db", opts[:database] || config[:database])
        |> append_param("epoch", encode_precision(opts[:precision]))
    end
  end

  @doc """
  Returns the proper URL for a `:status` request.
  """
  @spec status(Keyword.t()) :: String.t()
  def status(config), do: url(config, "status")

  @doc """
  Returns the proper URL for a `:write` request.
  """
  @spec write(Keyword.t(), Keyword.t()) :: String.t()
  def write(config, opts) do
    case config[:version] do
      :v2 ->
        config
        |> url("api/v2/write")
        |> append_param("bucket", opts[:bucket] || config[:bucket])
        |> append_param("org", opts[:org] || config[:org])
        |> append_param("precision", encode_precision(opts[:precision]))

      _ ->
        config
        |> url("write")
        |> append_param("db", opts[:database] || config[:database])
        |> append_param("precision", encode_precision(opts[:precision]))
        |> append_param("rp", opts[:retention_policy])
    end
  end

  @doc """
  Returns the proper URL for a `:delete` request.
  """
  @spec delete(Keyword.t(), Keyword.t()) :: String.t()
  def delete(config, opts) do
    config
    |> url("api/v2/delete")
    |> append_param("bucket", opts[:bucket] || config[:bucket])
    |> append_param("org", opts[:org] || config[:org])
  end

  defp append_param(url, _, nil), do: url
  defp append_param(url, _, ""), do: url

  defp append_param(url, key, value) do
    glue =
      if String.contains?(url, "?") do
        "&"
      else
        "?"
      end

    param = URI.encode_query([{key, value}])

    "#{url}#{glue}#{param}"
  end

  defp encode_precision(:hour), do: "h"
  defp encode_precision(:minute), do: "m"
  defp encode_precision(:second), do: "s"
  defp encode_precision(:millisecond), do: "ms"
  defp encode_precision(:microsecond), do: "u"
  defp encode_precision(:nanosecond), do: "ns"
  defp encode_precision(_), do: ""

  defp url(config, endpoint) do
    url =
      [
        config[:scheme],
        "://",
        config[:host],
        url_port(config[:port]),
        "/",
        endpoint
      ]
      |> IO.iodata_to_binary()

    case {config[:version], config[:auth][:method]} do
      {:v1, :query} ->
        url
        |> append_param("u", config[:auth][:username])
        |> append_param("p", config[:auth][:password])

      _ ->
        url
    end
  end

  defp url_port(port) when is_binary(port), do: [":", port]
  defp url_port(port) when is_integer(port), do: [":", Integer.to_string(port)]
  defp url_port(_), do: ""
end
