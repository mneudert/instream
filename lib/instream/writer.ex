defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  alias Instream.Query
  alias Instream.Response

  @optional_callbacks [
    init_worker: 1,
    terminate_worker: 1
  ]

  @type worker_state :: %{
          required(:module) => module,
          optional(term) => term
        }

  @doc """
  Called during worker initialization.

  This will be called for every process in the worker pool individually.
  """
  @callback init_worker(worker_state) :: worker_state

  @doc """
  Called during worker termination.

  This will be called for every process in the worker pool individually.
  """
  @callback terminate_worker(worker_state) :: :ok

  @doc """
  Writes a point.
  """
  @callback write(payload :: Query.t(), opts :: Keyword.t(), worker_state) ::
              Response.t()
end
