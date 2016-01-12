defmodule Instream.Validate do
  @moduledoc """
  Validation utility.
  """

  @doc """
  Validates a database name.

  If the validation succeeds the database name will be returned.

  Otherwise an `ArgumentError` will be raised.
  """
  @spec database!(String.t) :: String.t
  def database!(database) do
    test = ~r/^[a-zA-Z0-9_\-]+$/

    if not Regex.match?(test, database) do
      raise ArgumentError, "invalid database name: #{ inspect database }"
    end

    database
  end
end
