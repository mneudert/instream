defmodule Instream.Query.URL do
  @moduledoc """
  URL Utility.
  """

  alias Instream.Encoder.Precision


  @doc """
  Appends authentication credentials to an URL.
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
  Appends a database to an URL.
  """
  @spec append_database(String.t, String.t) :: String.t
  def append_database(url, nil),      do: url
  def append_database(url, database), do: url |> append_param("db", database)

  @doc """
  Appends an epoch value to an URL.

  The allowed values are identical to the precision parameters of write queries.
  """
  @spec append_epoch(String.t, Precision.t) :: String.t
  def append_epoch(url, nil),      do: url
  def append_epoch(url, epoch) do
    url |> append_param("epoch", Precision.encode(epoch))
  end

  @doc """
  Appends a precision value to an URL.
  """
  @spec append_precision(String.t, Precision.t) :: String.t
  def append_precision(url, nil),      do: url
  def append_precision(url, precision) do
    url |> append_param("precision", Precision.encode(precision))
  end

  @doc """
  Appends a query to an URL.
  """
  @spec append_query(String.t, String.t) :: String.t
  def append_query(url, query), do: url |> append_param("q", query)

  @doc """
  Returns the proper URL for a `:ping` request.
  """
  @spec ping(Keyword.t, String.t | nil) :: String.t
  def ping(conn, host \\ nil)

  def ping(conn, nil), do: conn |> url("ping")
  def ping(conn, host) do
    conn
    |> Keyword.put(:hosts, [ host ])
    |> url("ping")
  end

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(Keyword.t) :: String.t
  def query(conn), do: conn |> url("query")

  @doc """
  Returns the proper URL for a `:status` request.
  """
  @spec status(Keyword.t, String.t) :: String.t
  def status(conn, host \\ nil)

  def status(conn, nil), do: conn |> url("status")
  def status(conn, host) do
    conn
    |> Keyword.put(:hosts, [ host ])
    |> url("status")
  end

  @doc """
  Returns the proper URL for a `:write` request.
  """
  @spec write(Keyword.t) :: String.t
  def write(conn), do: conn |> url("write")


  defp append_param(url, _,   nil),  do: url
  defp append_param(url, _,   ""),   do: url
  defp append_param(url, key, value) do
    glue = case String.contains?(url, "?") do
      true  -> "&"
      false -> "?"
    end

    "#{ url }#{ glue }#{ key }=#{ URI.encode value }"
  end

  defp url(conn, endpoint) do
    [
      conn[:scheme], "://",
      url_host(conn[:hosts]), url_port(conn[:port]),
      "/", endpoint
    ]
    |> Enum.join("")
    |> append_auth(conn[:auth])
  end

  defp url_host(hosts), do: hosts |> hd()

  defp url_port(nil),  do: ""
  defp url_port(port), do: ":#{ port }"
end
