defmodule Instream.Encoder.Line do
  @moduledoc false

  @type point_map :: %{
          required(:fields) => [{term, term}],
          required(:measurement) => term,
          optional(:tags) => [{term, term}],
          optional(:timestamp) => term
        }

  @doc """
  Creates the write string for a list of data points.
  """
  @spec encode([point_map()]) :: binary
  def encode(points), do: encode(points, [])

  defp encode([], lines) do
    lines
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp encode([%{measurement: measurement} = point | points], lines) do
    line =
      [encode_property(measurement)]
      |> append_tags(point)
      |> append_fields(point)
      |> append_timestamp(point)
      |> Enum.join()

    encode(points, [line | lines])
  end

  defp append_fields(line, %{fields: fields}) do
    fields
    |> Enum.reduce([], fn
      {_, nil}, acc -> acc
      {field, value}, acc -> [",", encode_property(field), "=", encode_value(value) | acc]
    end)
    |> case do
      [] -> line
      ["," | encoded_fields] -> [line, " " | encoded_fields]
    end
  end

  defp append_tags(line, %{tags: tags}) do
    tags
    |> Enum.reduce([], fn
      {_, nil}, acc -> acc
      {tag, value}, acc -> [",", encode_property(tag), "=", encode_property(value) | acc]
    end)
    |> case do
      [] -> line
      encoded_tags -> [line | encoded_tags]
    end
  end

  defp append_tags(line, _), do: line

  defp append_timestamp(line, %{timestamp: nil}), do: line
  defp append_timestamp(line, %{timestamp: ts}), do: [line, " ", ts]
  defp append_timestamp(line, _), do: line

  defp encode_value(i) when is_integer(i), do: [Integer.to_string(i), "i"]
  defp encode_value(s) when is_binary(s), do: ["\"", String.replace(s, "\"", "\\\""), "\""]
  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(other), do: inspect(other)

  defp encode_property(s) do
    s
    |> Kernel.to_string()
    |> String.replace(",", "\\,", global: true)
    |> String.replace(" ", "\\ ", global: true)
    |> String.replace("=", "\\=", global: true)
  end
end
