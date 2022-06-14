defmodule Instream.HTTPClient.Hackney do
  @moduledoc """
  HTTP client using `:hackney.request/5`.

  See `Instream.Connection.Config` and `Instream.HTTPClient` if you want to
  replace the client with a library of your choice.
  """

  @behaviour Instream.HTTPClient

  @impl Instream.HTTPClient
  def request(:head, url, headers, body, opts),
    do: :hackney.request(:head, url, headers, body, opts)

  def request(method, url, headers, body, opts) do
    with {:ok, status, headers, client} <- :hackney.request(method, url, headers, body, opts),
         {:ok, body} <- :hackney.body(client) do
      {:ok, status, headers, body}
    else
      {:error, _} = error -> error
    end
  end
end
