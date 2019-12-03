defmodule Instream.Writer.Line do
  @moduledoc """
  Point writer for the line protocol.
  """

  alias Instream.Encoder.Line, as: Encoder
  alias Instream.Query.Headers
  alias Instream.Query.URL

  @behaviour Instream.Writer

  def write(%{payload: %{points: points}, opts: query_opts}, opts, %{module: conn})
      when is_list(points) and 0 < length(points) do
    config = conn.config()
    headers = Headers.assemble(config) ++ [{"Content-Type", "text/plain"}]
    body = Encoder.encode(points)

    url =
      config
      |> URL.write()
      |> URL.append_database(opts[:database] || config[:database])
      |> URL.append_precision(query_opts[:precision])
      |> URL.append_retention_policy(query_opts[:retention_policy])

    http_opts =
      Keyword.merge(Keyword.get(config, :http_opts, []), Keyword.get(opts, :http_opts, []))

    with {:ok, status, headers, client} <- :hackney.post(url, headers, body, http_opts),
         {:ok, body} <- :hackney.body(client) do
      {status, headers, body}
    else
      {:error, _} = error -> error
    end
  end

  def write(_, _, _), do: {200, [], ""}
end
