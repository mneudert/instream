defmodule Instream.Writer.JSON do
  @moduledoc """
  Point writer for the JSON protocol.
  """

  use Instream.Writer

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def write(payload, opts, conn) do
    headers = conn |> Headers.assemble()
    payload = payload |> Poison.encode!
    url     =
         conn
      |> URL.write()
      |> URL.append_database(opts[:database])

    { :ok, _, _, client } = :hackney.post(url, headers, payload)
    { :ok, response }     = :hackney.body(client)

    response
  end
end
