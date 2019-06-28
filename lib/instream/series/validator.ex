defmodule Instream.Series.Validator do
  @moduledoc false

  @doc """
  Checks if all mandatory definitions for a series are available.
  """
  @spec proper_series?(module) :: no_return
  def proper_series?(series) do
    _ =
      series
      |> defined?
      |> measurement?
      |> fields?
      |> forbidden_fields?
      |> forbidden_tags?
      |> field_tag_conflict?
  end

  defp defined?(series) do
    unless Module.defines?(series, {:__meta__, 1}, :def) do
      raise ArgumentError, "missing series definition in module #{series}"
    end

    series
  end

  defp field_tag_conflict?(series) do
    fields = series.__meta__(:fields)
    tags = series.__meta__(:tags)
    conflict = Enum.any?(fields, fn field -> Enum.member?(tags, field) end)

    if conflict do
      raise ArgumentError,
            "series #{series} contains at least one field and tag with the same name"
    end

    series
  end

  defp fields?(series) do
    if Enum.empty?(series.__meta__(:fields)) do
      raise ArgumentError, "series #{series} has no fields"
    end

    series
  end

  defp forbidden_fields?(series) do
    if Enum.any?(series.__meta__(:fields), &(&1 == :time)) do
      raise ArgumentError, "forbidden field :time defined in series #{series}"
    end

    series
  end

  defp forbidden_tags?(series) do
    if Enum.any?(series.__meta__(:tags), &(&1 == :time)) do
      raise ArgumentError, "forbidden tag :time defined in series #{series}"
    end

    series
  end

  defp measurement?(series) do
    unless series.__meta__(:measurement) do
      raise ArgumentError, "missing measurement for series #{series}"
    end

    series
  end
end
