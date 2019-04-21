defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  alias Instream.Query
  alias Instream.Response

  @doc """
  Writes a point.

  The `worker_state` parameter contains the state of the worker requesting the
  write operation. Please refer to the `Instream.Pool.Worker` module to see
  which parameters are available.
  """
  @callback write(payload :: Query.t(), opts :: Keyword.t(), worker_state :: map) :: Response.t()
end
