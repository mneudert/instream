defmodule Instream.Query.Read do
  @moduledoc """
  Executes `:read` queries..
  """

  use Instream.Query

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def execute(%Query{} = query, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
         conn
      |> URL.query()
      |> URL.append_database(opts[:database])
      |> URL.append_epoch(query.opts[:precision])
      |> URL.append_query(query.payload)

    { :ok, status, headers, client } = :hackney.get(url, headers)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response } |> maybe_parse(opts)
  end
end
