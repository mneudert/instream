defmodule Instream.Query.Read do
  @moduledoc """
  Executes `:read` queries..
  """

  use Instream.Query

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def execute(%Query{ payload: payload }, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
         conn
      |> URL.query()
      |> URL.append_database(opts[:database])
      |> URL.append_query(payload)

    { :ok, _, _, client } = :hackney.get(url, headers)
    { :ok, response }     = :hackney.body(client)

    response |> maybe_parse(opts)
  end
end
