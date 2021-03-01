defmodule Instream.HTTPClient do
  @moduledoc """
  Behaviour definition for pluggable HTTP clients.
  """

  @type response ::
          {:ok, status :: pos_integer, headers :: list}
          | {:ok, status :: pos_integer, headers :: list, body :: binary}
          | {:error, term}

  @callback request(method :: atom, url :: binary, headers :: list, body :: binary, opts :: list) ::
              response
end
