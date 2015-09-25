defmodule Instream.Query.Cluster do
  @moduledoc """
  Executes `:cluster` queries..
  """

  use Instream.Query

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def execute(%Query{ payload: payload }, opts, conn) do
    headers = conn |> Headers.assemble()
    url     =
         conn
      |> URL.query()
      |> URL.append_query(payload)

    { :ok, status, headers, client } = :hackney.get(url, headers)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response } |> maybe_parse(opts)
  end
end
