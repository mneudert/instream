defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  alias Instream.Query
  alias Instream.Response

  @optional_callbacks [
    writer_workers: 1
  ]

  @doc """
  Writes a point.
  """
  @callback write(payload :: Query.t(), opts :: Keyword.t(), conn :: module) :: Response.t()

  @doc """
  Optional list of workers to be supervised by the connection.
  """
  @callback writer_workers(conn :: module) :: [:supervisor.child_spec() | {module, term} | module]
end
