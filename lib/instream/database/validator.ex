defmodule Instream.Database.Validator do
  @moduledoc false

  @doc """
  Checks if all mandatory definitions for a database are available.
  """
  @spec proper_database?(module) :: no_return
  def proper_database?(database) do
    _ =
      database
      |> defined?
      |> name?
  end

  defp defined?(database) do
    unless Module.defines?(database, {:__meta__, 1}, :def) do
      raise ArgumentError, "missing database definition in module #{database}"
    end

    database
  end

  defp name?(database) do
    unless database.__meta__(:name) do
      raise ArgumentError, "missing name for database #{database}"
    end

    database
  end
end
