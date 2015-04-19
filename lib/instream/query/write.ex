defmodule Instream.Query.Write do
  @moduledoc """
  Executes `:write` queries..
  """

  use Instream.Query

  def execute(%Query{ payload: payload }, opts, conn) do
    url =
         conn
      |> URL.write()
      |> URL.append_database(opts[:database])

    { :ok, _, _, client } = :hackney.post(url, [], payload)
    { :ok, response }     = :hackney.body(client)

    response |> maybe_parse(opts)
  end
end
