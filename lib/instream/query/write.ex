defmodule Instream.Query.Write do
  @moduledoc """
  Executes `:write` queries..
  """

  use Instream.Query

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def execute(%Query{ payload: payload }, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
         conn
      |> URL.write()
      |> URL.append_database(opts[:database])

    { :ok, _, _, client } = :hackney.post(url, headers, payload)
    { :ok, response }     = :hackney.body(client)

    response |> maybe_parse(opts)
  end
end
