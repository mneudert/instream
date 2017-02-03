defmodule Instream.TestHelpers.Inets.Handler do
  @moduledoc false

  require Record

  Record.defrecord :mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl")

  def serve(mod_data), do: serve_uri(mod(mod_data, :request_uri), mod_data)


  defp serve_uri('/ping', _mod_data) do
    head = [
      code:         204,
      content_type: 'application/json'
    ]

    {:proceed, [{:response, {:response, head, ''}}]}
  end
end
