defmodule Instream.Writer.Line do
  @moduledoc """
  Point writer for the line protocol.

  ## Additional Write Options

  - `retention_policy`: write data with a specific retention policy
  """

  alias Instream.Encoder.Line, as: Encoder
  alias Instream.Query.Headers
  alias Instream.Query.URL

  @behaviour Instream.Writer

  @impl Instream.Writer
  def write(%{payload: [_ | _] = points, opts: query_opts}, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts) ++ [{"Content-Type", "text/plain"}]
    body = Encoder.encode(points)

    url =
      config
      |> URL.write()
      |> URL.append_database(query_opts[:database] || config[:database])
      |> URL.append_precision(query_opts[:precision])
      |> URL.append_retention_policy(query_opts[:retention_policy])

    http_opts =
      Keyword.merge(Keyword.get(config, :http_opts, []), Keyword.get(opts, :http_opts, []))

    config[:http_client].request(:post, url, headers, body, http_opts)
  end

  def write(_, _, _), do: {:ok, 200, [], ""}
end
