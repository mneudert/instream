defmodule Instream.Deleter.Predicate do
  @moduledoc """
  Point deleter for the line protocol.

  ### InfluxDB v2.x Options

  - `bucket`: delete data to a specific bucket
  - `org`: delete data to a specific organization
  """

  alias Instream.Query.Headers
  alias Instream.Query.URL

  @behaviour Instream.Deleter

  @impl Instream.Deleter
  def delete(points, opts, conn) do
    config = conn.config()
    headers = Headers.assemble(config, opts) ++ [{"Content-Type", "application/json"}]
    body = Jason.encode!(points)
    url = URL.delete(config, opts)

    http_opts =
      Keyword.merge(
        Keyword.get(config, :http_opts, []),
        Keyword.get(opts, :http_opts, [])
      )

    config[:http_client].request(:post, url, headers, body, http_opts)
  end
end
