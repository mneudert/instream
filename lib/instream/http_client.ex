defmodule Instream.HTTPClient do
  @moduledoc """
  Behaviour definition for pluggable HTTP clients.
  """

  @callback request(method :: atom, url :: binary, headers :: list, body :: binary, opts :: list) ::
              {:ok, status :: pos_integer, headers :: list}
              | {:ok, status :: pos_integer, headers :: list, body :: binary}
              | {:error, term}
end
