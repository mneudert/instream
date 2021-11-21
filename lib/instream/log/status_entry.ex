defmodule Instream.Log.StatusEntry do
  @moduledoc """
  Log entry definition for status requests.
  """

  defstruct host: nil,
            result: nil,
            metadata: nil

  @type t :: %__MODULE__{
          host: String.t(),
          result: :ok | :error,
          metadata: Instream.Log.Metadata.t()
        }
end
