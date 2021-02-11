defmodule Instream.Query do
  @moduledoc """
  Query struct.
  """

  defstruct payload: nil,
            opts: []

  @type payload_type :: String.t() | [map] | nil
  @type query_method :: :get | :post

  @type t :: %__MODULE__{
          payload: payload_type,
          opts: [{:method, query_method} | {atom, any}]
        }
end
