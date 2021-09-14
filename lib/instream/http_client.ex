defmodule Instream.HTTPClient do
  @moduledoc """
  Behaviour definition for pluggable HTTP clients.
  """

  @type method :: :get | :head | :post
  @type response ::
          {:ok, status :: pos_integer, headers :: list}
          | {:ok, status :: pos_integer, headers :: list, body :: binary}
          | {:error, term}

  @callback request(
              method :: method,
              url :: binary,
              headers :: list,
              body :: binary,
              opts :: list
            ) ::
              response
end
