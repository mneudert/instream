defmodule Instream.TestHelpers.Inets.Handler do
  @moduledoc false

  require Record

  Record.defrecord(:mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl"))

  def unquote(:do)(mod_data), do: serve_uri(mod(mod_data, :request_uri), mod_data)

  defp serve_uri('/ping', _mod_data) do
    head = [
      code: 204,
      content_type: 'application/json'
    ]

    {:proceed, [{:response, {:response, head, ''}}]}
  end

  defp serve_uri('/query?db=timeout', _mod_data) do
    :timer.sleep(100)

    body = '{"results": [{}]}'

    head = [
      code: 200,
      content_length: body |> length() |> String.to_charlist(),
      content_type: 'application/json'
    ]

    {:proceed, [{:response, {:response, head, body}}]}
  end

  defp serve_uri('/query?db=timeout_long', _mod_data) do
    :timer.sleep(10000)

    body = '{"results": [{}]}'

    head = [
      code: 200,
      content_length: body |> length() |> String.to_charlist(),
      content_type: 'application/json'
    ]

    {:proceed, [{:response, {:response, head, body}}]}
  end
end
