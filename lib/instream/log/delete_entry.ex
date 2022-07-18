defmodule Instream.Log.DeleteEntry do
  @moduledoc """
  Log entry definition for delete requests.
  """

  defstruct points: nil,
            result: nil,
            metadata: nil,
            conn: nil

  @type t :: %__MODULE__{
          points: map(),
          result: term,
          metadata: Instream.Log.Metadata.t(),
          conn: module
        }
end
