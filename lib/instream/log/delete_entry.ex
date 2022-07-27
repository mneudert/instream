defmodule Instream.Log.DeleteEntry do
  @moduledoc """
  Log entry definition for delete requests.
  """

  defstruct payload: nil,
            result: nil,
            metadata: nil,
            conn: nil

  @type t :: %__MODULE__{
          payload: map(),
          result: term,
          metadata: Instream.Log.Metadata.t(),
          conn: module
        }
end
