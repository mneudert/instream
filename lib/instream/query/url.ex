defmodule Instream.Query.URL do
  @moduledoc false

  alias Instream.Encoder.Precision

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
  @spec append_epoch(String.t(), Precision.t()) :: String.t()
  def append_epoch(url, nil), do: url

  def append_epoch(url, epoch), do: append_param(url, "epoch", Precision.encode(epoch))

  @doc """
  Appends a (json encoded) parameter map to a URL.
  """
  @spec append_json_params(String.t(), String.t()) :: String.t()
  def append_json_params(url, json_params) do
    url |> append_param("params", json_params)
  end

  @doc """
  Appends a precision value to a URL.
  """
  @spec append_precision(String.t(), Precision.t()) :: String.t()
  def append_precision(url, nil), do: url

  def append_precision(url, precision),
    do: append_param(url, "precision", Precision.encode(precision))

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
  @spec ping(Keyword.t(), String.t() | nil) :: String.t()
  def ping(config, host \\ nil)

  def ping(config, nil), do: url(config, "ping")

  def ping(config, host) do
    config
    |> Keyword.put(:host, host)
    |> url("ping")
  end

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(Keyword.t(), atom | nil) :: String.t()
  def query(config, :flux), do: url(config, "api/v2/query")
  def query(config, _), do: url(config, "query")

  @doc """
  Returns the proper URL for a `:status` request.
  """
  @spec status(Keyword.t(), String.t() | nil) :: String.t()
  def status(config, host \\ nil)

  def status(config, nil), do: url(config, "status")

  def status(config, host) do
    config
    |> Keyword.put(:host, host)
    |> url("status")
  end

  @doc """
  Returns the proper URL for a `:write` request.
  """
  @spec write(Keyword.t()) :: String.t()
  def write(config), do: url(config, "write")

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
