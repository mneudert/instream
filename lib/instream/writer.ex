defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  alias Instream.Encoder.Line
  alias Instream.HTTPClient

  @optional_callbacks [
    writer_workers: 1
  ]

  @doc """
  Writes a point.
  """
  @callback write(payload :: [Line.point()], opts :: Keyword.t(), conn :: module) ::
              HTTPClient.response()

  @doc """
  Optional list of workers to be supervised by the connection.
  """
  @callback writer_workers(conn :: module) :: [:supervisor.child_spec() | {module, term} | module]
end
