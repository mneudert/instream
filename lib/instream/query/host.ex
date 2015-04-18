defmodule Instream.Query.Host do
  @moduledoc """
  Executes `:host` queries..
  """

  use Instream.Query

  def execute(%Query{ query: query }, opts, conn) do
    url =
         conn
      |> URL.query()
      |> URL.append_query(query)

    { :ok, _, _, client } = :hackney.get(url)
    { :ok, response }     = :hackney.body(client)

    response |> maybe_parse(opts)
  end
end
