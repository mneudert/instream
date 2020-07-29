defmodule Instream.Log.QueryEntry do
  @moduledoc """
  Log entry definition for query requests.
  """

  defstruct query: nil,
            result: nil,
            metadata: nil

  @type t :: %__MODULE__{
          query: String.t(),
          result: term,
          metadata: Instream.Log.Metadata.t()
        }
end
