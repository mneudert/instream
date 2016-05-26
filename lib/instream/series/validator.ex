defmodule Instream.Series.Validator do
  @moduledoc """
  Performs compile time validations of series definitions.
  """

  @doc """
  Checks if all mandatory definitions for a series are available.
  """
  @spec proper_series?(atom) :: no_return
  def proper_series?(series) do
    _ =
      series
      |> defined?
      |> measurement?
  end


  defp defined?(series) do
    case Module.defines?(series, { :__meta__, 1 }, :def) do
      false -> raise ArgumentError, "missing series definition in module #{ series }"
      _     -> series
    end
  end

  defp measurement?(series) do
    case series.__meta__(:measurement) do
      nil -> raise ArgumentError, "missing measurement for series #{ series }"
      _   -> series
    end
  end
end
