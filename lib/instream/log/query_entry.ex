defmodule Instream.Log.QueryEntry do
  @moduledoc """
  Log entry definition for query requests.
  """

  defstruct [
    query: nil
  ]

  @type t :: %__MODULE__{
    query: String.t
  }
end
