defmodule Instream.Log.StatusEntry do
  @moduledoc """
  Log entry definition for status requests.
  """

  defstruct [
    host:   nil,
    result: nil
  ]

  @type t :: %__MODULE__{
    host:   String.t,
    result: atom
  }
end
