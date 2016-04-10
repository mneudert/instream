defmodule Instream.Log.StatusEntry do
  @moduledoc """
  Log entry definition for status requests.
  """

  defstruct [
    result: nil
  ]

  @type t :: %__MODULE__{
    result: atom
  }
end
