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
    case Module.defines?(database, {:__meta__, 1}, :def) do
      false -> raise ArgumentError, "missing database definition in module #{database}"
      _ -> database
    end
  end

  defp name?(database) do
    case database.__meta__(:name) do
      nil -> raise ArgumentError, "missing name for database #{database}"
      _ -> database
    end
  end
end
