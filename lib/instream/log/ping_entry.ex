defmodule Instream.Log.PingEntry do
  @moduledoc """
  Log entry definition for ping requests.
  """

  defstruct host: nil,
            result: nil,
            metadata: nil

  @type t :: %__MODULE__{
          host: String.t(),
          result: :pong | :error,
          metadata: Instream.Log.Metadata.t()
        }
end
