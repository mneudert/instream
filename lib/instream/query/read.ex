defmodule Instream.Query.Read do
  @moduledoc """
  Executes `:read` queries..
  """

  alias Instream.Query
  alias Instream.Query.URL

  @doc """
  Executes the query.
  """
  @spec execute(query :: Query.t, opts :: Keyword.t, conn :: Keyword.t) :: any
  def execute(%Query{ query: query }, opts, conn) do
    url =
         conn
      |> URL.query()
      |> URL.append_database(opts[:database])
      |> URL.append_query(query)

    { :ok, _, _, client } = :hackney.get(url)
    { :ok, response }     = :hackney.body(client)

    response |> maybe_parse(opts)
  end


  defp maybe_parse(response, [ result_as: :raw ]), do: response

  defp maybe_parse(response, _) do
    response |> Poison.decode!(keys: :atoms)
  end
end
