defmodule Instream.Validate do
  @moduledoc """
  Validation utility.
  """

  @doc """
  Validates a database name.
  """
  @spec database!(database :: String.t) :: :ok
  def database!(database) do
    test = ~r/^[a-zA-Z0-9_\-]+$/

    if not Regex.match?(test, database) do
      raise ArgumentError, "invalid database name: #{ inspect database }"
    end

    :ok
  end
end
