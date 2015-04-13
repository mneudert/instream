defmodule Instream.Query.URL do
  @moduledoc """
  URL Utility.
  """

  @doc """
  Appends a database to an URL.
  """
  @spec append_database(url :: String.t, database :: String.t) :: String.t
  def append_database(url, nil),      do: url
  def append_database(url, database), do: url |> append_param("db", database)

  @doc """
  Appends a query to an URL.
  """
  @spec append_query(url :: String.t, query :: String.t) :: String.t
  def append_query(url, query), do: url |> append_param("q", query)

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(conn :: Keyword.t) :: String.t
  def query(conn) do
    [
      conn[:scheme], "://",
      url_credentials(conn[:username], conn[:password]),
      url_host(conn[:hosts]), url_port(conn[:port]),
      "/query"
    ]
    |> Enum.join("")
  end


  defp append_param(url, key, value) do
    glue = case String.contains?(url, "?") do
      true  -> "&"
      false -> "?"
    end

    "#{ url }#{ glue }#{ key }=#{ URI.encode value }"
  end

  defp url_credentials(nil,  nil),  do: ""
  defp url_credentials(user, pass), do: "#{ user }:#{ pass }@"

  defp url_host(hosts), do: hosts |> hd()

  defp url_port(nil),  do: ""
  defp url_port(port), do: ":#{ port }"
end
