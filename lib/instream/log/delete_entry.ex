defmodule Instream.Log.DeleteEntry do
  @moduledoc """
  Log entry definition for delete requests.
  """

  defstruct points: nil,
            result: nil,
            conn: nil

  @type t :: %__MODULE__{
          points: map(),
          result: term,
          conn: module
        }
end
