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
      |> fields?
  end


  defp defined?(series) do
    case Module.defines?(series, { :__meta__, 1 }, :def) do
      false -> raise ArgumentError, "missing series definition in module #{ series }"
      _     -> series
    end
  end

  defp fields?(series) do
    if 0 == length(series.__meta__(:fields)) do
      IO.write :stderr, """
      The series "#{ series }"
      has been defined without fields.

      This behaviour has been deprecated
      and will stop working in a future version.
      """
    end

    series
  end

  defp measurement?(series) do
    case series.__meta__(:measurement) do
      nil -> raise ArgumentError, "missing measurement for series #{ series }"
      _   -> series
    end
  end
end
