defmodule Instream.Series.Validator do
  @moduledoc false

  @forbidden_keys [:_field, :_measurement, :time]

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

  defp conflict_message(conflicts) do
    conflicts
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
    |> Enum.join(", ")
  end

  defp defined?(series) do
    unless Module.defines?(series, {:__meta__, 1}, :def) do
      raise ArgumentError, "missing series definition in module #{series}"
    end

    series
  end

  defp field_tag_conflict?(series) do
    fields = :fields |> series.__meta__() |> MapSet.new()
    tags = :tags |> series.__meta__() |> MapSet.new()
    conflicts = MapSet.intersection(fields, tags) |> MapSet.to_list()

    unless [] == conflicts do
      raise ArgumentError,
            "series #{series} contains fields and tags with the same name: " <>
              conflict_message(conflicts)
    end

    series
  end

  defp fields?(series) do
    if [] == series.__meta__(:fields) do
      raise ArgumentError, "series #{series} has no fields"
    end

    series
  end

  defp forbidden_fields?(series) do
    fields = :fields |> series.__meta__() |> MapSet.new()
    conflicts = @forbidden_keys |> MapSet.new() |> MapSet.intersection(fields) |> MapSet.to_list()

    unless [] == conflicts do
      raise ArgumentError,
            "series #{series} contains forbidden fields: " <>
              conflict_message(conflicts)
    end

    series
  end

  defp forbidden_tags?(series) do
    tags = :tags |> series.__meta__() |> MapSet.new()
    conflicts = @forbidden_keys |> MapSet.new() |> MapSet.intersection(tags) |> MapSet.to_list()

    unless [] == conflicts do
      raise ArgumentError,
            "series #{series} contains forbidden tags: " <>
              conflict_message(conflicts)
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
