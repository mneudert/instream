defmodule Instream.Query do
  @moduledoc """
  Query struct.
  """

  defstruct [
    payload: nil,
    opts:    [],
    type:    nil
  ]

  @type payload_type :: String.t
  @type query_type   :: :ping | :read | :write

  @type t :: %__MODULE__{
    payload: payload_type,
    opts:    Keyword.t,
    type:    query_type
  }
end
