defmodule Instream.Log.PingEntry do
  @moduledoc """
  Log entry definition for ping requests.
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
