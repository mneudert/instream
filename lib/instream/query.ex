defmodule Instream.Query do
  @moduledoc """
  Query definition.
  """

  defstruct [
    query: "",
    type:  nil
  ]

  @type query_type :: :host | :read | :write

  @type t :: %__MODULE__{
    query: String.t,
    type:  query_type
  }
end
