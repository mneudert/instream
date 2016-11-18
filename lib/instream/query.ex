defmodule Instream.Query do
  @moduledoc """
  Query struct.
  """

  defstruct [
    method:  :get,
    payload: nil,
    opts:    [],
    type:    nil
  ]

  @type payload_type :: String.t | map
  @type query_method :: :get | :post
  @type query_type   :: :ping | :read | :write

  @type t :: %__MODULE__{
    method:  query_method,
    payload: payload_type,
    opts:    Keyword.t,
    type:    query_type
  }
end
