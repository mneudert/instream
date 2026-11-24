defmodule Instream.HTTPClient.Hackney do
  @moduledoc """
  HTTP client using `:hackney.request/5`.

  See `Instream.Connection.Config` and `Instream.HTTPClient` if you want to
  replace the client with a library of your choice.
  """

  @behaviour Instream.HTTPClient

  @impl Instream.HTTPClient
  def request(method, url, headers, body, opts),
    do: :hackney.request(method, url, headers, body, opts)
end
