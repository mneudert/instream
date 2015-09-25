defmodule Instream.Writer.Line do
  @moduledoc """
  Point writer for the line protocol.
  """

  use Instream.Writer

  alias Instream.Query.Headers
  alias Instream.Query.URL


  def write(payload, opts, conn) do
    headers = Headers.assemble(conn) ++ [{ 'Content-Type', 'text/plain' }]
    body    = payload |> to_line()

    db  = Map.get(payload, :database, opts[:database])
    url =
         conn
      |> URL.write()
      |> URL.append_database(db)

    { :ok, status, headers, client } = :hackney.post(url, headers, body)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response }
  end


  @doc false
  def to_line(payload), do: payload |> Map.get(:points, []) |> to_line("")


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

  defp append_timestamp(line, %{ time: nil }), do: line
  defp append_timestamp(line, %{ time: ts }),  do: "#{ line } #{ ts }"
  defp append_timestamp(line, _),              do: line

  defp to_line([],                 line), do: line
  defp to_line([ point | points ], line)  do
    line =
         (line <> encode_property(point.measurement))
      |> append_tags(point)
      |> append_fields(point)
      |> append_timestamp(point)

    to_line(points, line)
  end
end
