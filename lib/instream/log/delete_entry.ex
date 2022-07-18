defmodule Instream.Log.DeleteEntry do
  @moduledoc """
  Log entry definition for delete requests.
  """

  defstruct payload: nil,
            result: nil,
            conn: nil

  @type t :: %__MODULE__{
          payload: map(),
          result: term,
          conn: module
        }
end
