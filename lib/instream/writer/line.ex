defmodule Instream.Writer.Line do
  @moduledoc """
  Point writer for the line protocol.
  """

  use Instream.Writer

  alias Instream.Encoder.Line, as: Encoder
  alias Instream.Query.Headers
  alias Instream.Query.URL


  def write(query, opts, %{ module: conn }) do
    config  = conn.config()
    headers = Headers.assemble(config) ++ [{ 'Content-Type', 'text/plain' }]
    body    = query.payload |> to_line()

    url =
         config
      |> URL.write()
      |> URL.append_database(opts[:database])
      |> URL.append_precision(query.opts[:precision])

    http_opts = Keyword.get(config, :http_opts, [])

    { :ok, status, headers, client } = :hackney.post(url, headers, body, http_opts)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response }
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> Encoder.encode()
end
