defmodule Instream.Query do
  @moduledoc """
  Query struct.
  """

  defstruct method: :get,
            payload: nil,
            opts: [],
            type: nil

  @type payload_type :: String.t() | [map] | nil
  @type query_method :: :get | :post
  @type query_type :: :read | :write

  @type t :: %__MODULE__{
          payload: payload_type,
          opts: [{:method, query_method} | {atom, any}],
          type: query_type
        }
end
