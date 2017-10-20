defmodule Instream.Log.Metadata do
  @moduledoc """
  Metadata common to all log entries.
  """

  defstruct query_time: nil,
            response_status: nil

  @type t :: %__MODULE__{
          query_time: non_neg_integer,
          response_status: non_neg_integer
        }
end
