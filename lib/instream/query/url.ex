defmodule Instream.Query.URL do
  @moduledoc """
  URL Utility.
  """

  alias Instream.Encoder.Precision


  @doc """
  Appends authentication credentials to a URL.
  """
  @spec append_auth(String.t, Keyword.t) :: String.t
  def append_auth(url, nil), do: url
  def append_auth(url, auth) do
    case auth[:method] do
      :query ->
        url
        |> append_param("u", auth[:username])
        |> append_param("p", auth[:password])

      _ -> url
    end
  end

  @doc """
  Appends a database to a URL.
  """
  @spec append_database(String.t, String.t) :: String.t
  def append_database(url, nil),      do: url
  def append_database(url, database), do: url |> append_param("db", database)

  @doc """
  Appends an epoch value to a URL.

  The allowed values are identical to the precision parameters of write queries.
  """
  @spec append_epoch(String.t, Precision.t) :: String.t
  def append_epoch(url, nil),      do: url
  def append_epoch(url, epoch) do
    url |> append_param("epoch", Precision.encode(epoch))
  end

  @doc """
  Appends a precision value to a URL.
  """
  @spec append_precision(String.t, Precision.t) :: String.t
  def append_precision(url, nil),      do: url
  def append_precision(url, precision) do
    url |> append_param("precision", Precision.encode(precision))
  end

  @doc """
  Appends a retention policy to a URL.
  """
  @spec append_retention_policy(String.t, String.t) :: String.t
  def append_retention_policy(url, nil),   do: url
  def append_retention_policy(url, policy) do
    url |> append_param("rp", policy)
  end

  @doc """
  Appends a query to a URL.
  """
  @spec append_query(String.t, String.t) :: String.t
  def append_query(url, query), do: url |> append_param("q", query)

  @doc """
  Returns the proper URL for a `:ping` request.
  """
  @spec ping(Keyword.t, String.t | nil) :: String.t
  def ping(config, host \\ nil)

  def ping(config, nil), do: config |> url("ping")
  def ping(config, host) do
    config
    |> Keyword.put(:host, host)
    |> url("ping")
  end

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(Keyword.t) :: String.t
  def query(config), do: config |> url("query")

  @doc """
  Returns the proper URL for a `:status` request.
  """
  @spec status(Keyword.t, String.t | nil) :: String.t
  def status(config, host \\ nil)

  def status(config, nil), do: config |> url("status")
  def status(config, host) do
    config
    |> Keyword.put(:host, host)
    |> url("status")
  end

  @doc """
  Returns the proper URL for a `:write` request.
  """
  @spec write(Keyword.t) :: String.t
  def write(config), do: config |> url("write")


  defp append_param(url, _,   nil),  do: url
  defp append_param(url, _,   ""),   do: url
  defp append_param(url, key, value) do
    glue = case String.contains?(url, "?") do
      true  -> "&"
      false -> "?"
    end

    "#{ url }#{ glue }#{ key }=#{ URI.encode value }"
  end

  defp url(config, endpoint) do
    [
      config[:scheme], "://",
      config[:host], url_port(config[:port]),
      "/", endpoint
    ]
    |> Enum.join("")
    |> append_auth(config[:auth])
  end

  defp url_port(nil),  do: ""
  defp url_port(port), do: ":#{ port }"
end
