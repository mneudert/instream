defmodule Instream.HTTPClient.Hackney do
  @moduledoc """
  Hackney HTTP client.
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
