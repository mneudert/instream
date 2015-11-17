defmodule Instream.Encoder.Line do
  @moduledoc """
  Encoder module for the line protocol.

  Takes a list of points and returns the data string to be passed
  to the write endpoint of influxdb.
  """

  @doc """
  Creates the write string for a list of data points.
  """
  @spec encode([ map ]) :: String.t
  def encode(points), do: points |> encode("")


  defp encode([],                 line), do: String.rstrip(line)
  defp encode([ point | points ], line)  do
    line =
         (line <> encode_property(point.measurement))
      |> append_tags(point)
      |> append_fields(point)
      |> append_timestamp(point)

    encode(points, line)
  end


  defp append_fields(line, %{ fields: fields }) do
    "#{ line } #{ encode_fields(fields) }"
  end

  defp append_tags(line, %{ tags: tags }) do
    tags
    |> Enum.reduce([], fn ({ tag, value }, acc)->
         [ "#{ encode_property(tag) }=#{ encode_property(value) }" | acc ]
       end)
    |> List.insert_at(0, line)
    |> Enum.join(",")
  end

  defp append_tags(line, _), do: line

  defp append_timestamp(line, %{ timestamp: nil }), do: line
  defp append_timestamp(line, %{ timestamp: ts }),  do: "#{ line } #{ ts }\n"
  defp append_timestamp(line, _),                   do: line


  defp encode_fields(fields) do
    fields
    |> Enum.filter(fn
         { _, nil } -> false
         { _, _ }   -> true
       end)
    |> Enum.reduce([], fn ({ field, value }, acc)->
         [ "#{ encode_property(field) }=#{ encode_value(value) }" | acc ]
       end)
    |> Enum.join(",")
  end

  defp encode_value(i) when is_integer(i), do: "#{ i }i"
  defp encode_value(s) when is_binary(s),  do: "\"#{ String.replace(s, "\"", "\\\"") }\""
  defp encode_value(true),                 do: "true"
  defp encode_value(false),                do: "false"
  defp encode_value(other),                do: inspect(other)

  defp encode_property(s) do
    s
    |> Kernel.to_string
    |> String.replace(",", "\\,", global: true)
    |> String.replace(" ", "\\ ", global: true)
    |> String.replace("=", "\\=", global: true)
  end
end
