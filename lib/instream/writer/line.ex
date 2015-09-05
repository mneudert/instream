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

    { :ok, _, _, client } = :hackney.post(url, headers, body)
    { :ok, response }     = :hackney.body(client)

    response
  end


  defp append_fields(line, point) do
    fields = Map.keys(point.fields) |> Enum.map fn (field) ->
      value = point.fields[field]

      cond do
        is_binary(value)  -> "#{ field }=\"#{ value }\""
        is_boolean(value) -> "#{ field }=#{ value && "true" || "false" }"
        is_integer(value) -> "#{ field }=#{ value }i"
        true              -> "#{ field }=#{ inspect value }"
      end
    end

    fields = Enum.filter(fields, fn (el) -> nil != el end)

    line <> " " <> Enum.join(fields, ",")
  end

  defp append_tags(line, point) do
    tags = Map.keys(point.tags) |> Enum.map fn (tag) ->
      "#{ tag }=#{ point.tags[tag] }"
    end

    Enum.join([ line ] ++ tags, ",")
  end

  defp to_line(payload), do: payload |> Map.get(:points, []) |> to_line("")

  defp to_line([],                 line), do: line
  defp to_line([ point | points ], line)  do
    line =
         (line <> point.measurement)
      |> append_tags(point)
      |> append_fields(point)

    to_line(points, line)
  end
end
