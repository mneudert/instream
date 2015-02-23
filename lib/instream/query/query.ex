defmodule Instream.Query.Query do
  @moduledoc """
  Executes `:query` queries..
  """

  alias Instream.Query
  alias Instream.Query.URL

  @doc """
  Executes the query.
  """
  @spec execute(query :: Query.t, conn :: Keyword.t) :: any
  def execute(%Query{ query: query }, conn) do
    url =
         conn
      |> URL.query()
      |> URL.append_query(query)

    { :ok, _, _, client } = :hackney.get(url)
    { :ok, response }     = :hackney.body(client)

    response |> Poison.decode!(keys: :atoms)
  end
end
