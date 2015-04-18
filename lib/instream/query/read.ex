defmodule Instream.Query.Read do
  @moduledoc """
  Executes `:read` queries..
  """

  use Instream.Query

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
end
