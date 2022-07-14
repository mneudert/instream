defmodule Instream.Deleter do
  @moduledoc """
  Point deleter behaviour.
  """

  alias Instream.HTTPClient

  @optional_callbacks [
    deleter_workers: 1
  ]

  @doc """
  Deletes a point.
  """
  @callback delete(payload :: map(), opts :: Keyword.t(), conn :: module) ::
              HTTPClient.response()

  @doc """
  Optional list of workers to be supervised by the connection.
  """
  @callback deleter_workers(conn :: module) :: [
              :supervisor.child_spec() | {module, term} | module
            ]
end
