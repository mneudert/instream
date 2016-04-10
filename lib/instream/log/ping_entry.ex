defmodule Instream.Log.PingEntry do
  @moduledoc """
  Log entry definition for ping requests.
  """

  defstruct [
    result: nil
  ]

  @type t :: %__MODULE__{
    result: atom
  }
end
