defmodule Instream.Query.URL do
  @moduledoc """
  URL Utility.
  """

  @doc """
  Appends a query to an URL.
  """
  @spec append_query(url :: String.t, query :: String.t) :: String.t
  def append_query(url, query) do
    case String.contains?(url, "?") do
      true  -> "#{ url }&q=#{ URI.encode query }"
      false -> "#{ url }?q=#{ URI.encode query }"
    end
  end

  @doc """
  Returns the proper URL for a `:query` request.
  """
  @spec query(conn :: Keyword.t) :: String.t
  def query(conn) do
    [
      conn[:scheme], "://",
      credentials(conn[:username], conn[:password]),
      host(conn[:hosts]), port(conn[:port]),
      "/query"
    ]
    |> Enum.join("")
  end


  defp credentials(nil,  nil),  do: ""
  defp credentials(user, pass), do: "#{ user }:#{ pass }@"

  defp host(hosts), do: hosts |> hd()

  defp port(nil),  do: ""
  defp port(port), do: ":#{ port }"
end
