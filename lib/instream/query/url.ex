defmodule Instream.Query.URL do
  @moduledoc false

  alias Instream.Connection

  @doc """
  Appends authentication credentials to a URL.
  """
  @spec append_auth(String.t(), Keyword.t()) :: String.t()
  def append_auth(url, nil), do: url

  def append_auth(url, auth) do
    case auth[:method] do
      :query ->
        url
        |> append_param("u", auth[:username])
        |> append_param("p", auth[:password])

      _ ->
        url
    end
  end

  @doc """
  Appends a database to a URL.
  """
  @spec append_database(String.t(), String.t()) :: String.t()
  def append_database(url, nil), do: url
  def append_database(url, database), do: append_param(url, "db", database)

  @doc """
  Appends an epoch value to a URL.

  The allowed values are identical to the precision parameters of write queries.
  """
  @spec append_epoch(String.t(), Connection.precision()) :: String.t()
  def append_epoch(url, nil), do: url
  def append_epoch(url, epoch), do: append_param(url, "epoch", encode_precision(epoch))

  @doc """
  Appends a (json encoded) parameter map to a URL.
  """
  @spec append_json_params(String.t(), String.t()) :: String.t()
  def append_json_params(json_params, url), do: append_param(url, "params", json_params)

  @doc """
  Appends a precision value to a URL.
  """
  @spec append_precision(String.t(), Connection.precision()) :: String.t()
  def append_precision(url, nil), do: url

  def append_precision(url, precision),
    do: append_param(url, "precision", encode_precision(precision))

  @doc """
  Appends a retention policy to a URL.
  """
  @spec append_retention_policy(String.t(), String.t()) :: String.t()
  def append_retention_policy(url, nil), do: url
  def append_retention_policy(url, policy), do: append_param(url, "rp", policy)

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
      {:v2, _} ->
        config
        |> url("api/v2/query")
        |> append_param("org", opts[:org] || config[:org])

      {:v1, :flux} ->
        config
        |> url("api/v2/query")
        |> append_param("db", opts[:database] || config[:database])

      {:v1, _} ->
        config
        |> url("query")
        |> append_param("db", opts[:database] || config[:database])
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

      _ ->
        config
        |> url("write")
        |> append_param("db", opts[:database] || config[:database])
    end
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
  defp encode_precision(:rfc3339), do: ""

  defp url(config, endpoint) do
    [
      config[:scheme],
      "://",
      config[:host],
      url_port(config[:port]),
      "/",
      endpoint
    ]
    |> Enum.join("")
    |> append_auth(config[:auth])
  end

  defp url_port(nil), do: ""
  defp url_port(port), do: ":#{port}"
end
