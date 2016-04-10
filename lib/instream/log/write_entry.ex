defmodule Instream.Log.WriteEntry do
  @moduledoc """
  Log entry definition for write requests.
  """

  defstruct [
    points:   nil,
    metadata: nil
  ]

  @type t :: %__MODULE__{
    points:   non_neg_integer,
    metadata: Instream.Log.Metadata.t
  }
end
