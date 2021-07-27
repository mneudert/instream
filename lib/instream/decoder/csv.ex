defmodule Instream.Decoder.CSV do
  @moduledoc false

  alias Instream.Decoder.RFC3339

  NimbleCSV.define(__MODULE__.Parser, separator: ",", escape: "\"")

  @doc """
  Converts a full CSV response into a list of maps.
  """
  @spec parse(binary) :: [map]
  def parse(response) do
    response
    |> String.trim_trailing("\r\n\r\n")
    |> String.split(["\r\n\r\n"])
    |> case do
      [table | []] -> parse_table(table)
      [_ | _] = tables -> Enum.map(tables, &parse_table/1)
      _ -> []
    end
  end

  defp apply_defaults(row, [], []), do: row

  defp apply_defaults(["" | rest], [value | defaults], acc),
    do: apply_defaults(rest, defaults, [value | acc])

  defp apply_defaults([value | rest], [_ | defaults], acc),
    do: apply_defaults(rest, defaults, [value | acc])

  defp apply_defaults([], [], acc), do: Enum.reverse(acc)

  defp parse_annotations([["#datatype" | _ = datatypes] | rest], acc),
    do: parse_annotations(rest, %{acc | datatypes: datatypes})

  defp parse_annotations([["#default" | _ = defaults] | rest], acc),
    do: parse_annotations(rest, %{acc | defaults: defaults})

  defp parse_annotations([["#group" | _ = groups] | rest], acc),
    do: parse_annotations(rest, %{acc | groups: groups})

  defp parse_annotations(rest, acc), do: %{acc | table: rest}

  defp parse_datatypes({{field, "boolean"}, "false"}), do: {field, false}
  defp parse_datatypes({{field, "boolean"}, "true"}), do: {field, true}
  defp parse_datatypes({{field, "double"}, value}), do: {field, String.to_float(value)}
  defp parse_datatypes({{field, "long"}, value}), do: {field, String.to_integer(value)}

  defp parse_datatypes({{field, "dateTime:RFC3339"}, value}),
    do: {field, RFC3339.to_nanosecond(value)}

  defp parse_datatypes({{field, _}, value}), do: {field, value}


  defp parse_rows(%{table: [[""]]}), do: []

  defp parse_rows(%{
         datatypes: [_ | _] = datatypes,
         defaults: defaults,
         table: [["" | _ = headers] | [_ | _] = rows]
       }) do
    Enum.map(rows, fn ["" | row] ->
      headers
      |> Enum.zip(datatypes)
      |> Enum.zip(apply_defaults(row, defaults, []))
      |> Enum.map(&parse_datatypes/1)
      |> Map.new()
    end)
  end

  defp parse_rows(%{
         datatypes: [_ | _] = datatypes,
         defaults: defaults,
         table: [[_ | _] = headers | [_ | _] = rows]
       }) do
    Enum.map(rows, fn row ->
      headers
      |> Enum.zip(datatypes)
      |> Enum.zip(apply_defaults(row, defaults, []))
      |> Enum.map(&parse_datatypes/1)
      |> Map.new()
    end)
  end

  defp parse_rows(%{defaults: defaults, table: [["" | _ = headers] | [_ | _] = rows]}) do
    Enum.map(rows, fn ["" | row] ->
      headers
      |> Enum.zip(apply_defaults(row, defaults, []))
      |> Map.new()
    end)
  end

  defp parse_rows(%{defaults: defaults, table: [[_ | _] = headers | [_ | _] = rows]}) do
    Enum.map(rows, fn row ->
      headers
      |> Enum.zip(apply_defaults(row, defaults, []))
      |> Map.new()
    end)
  end

  defp parse_table(table) do
    table
    |> __MODULE__.Parser.parse_string(skip_headers: false)
    |> parse_annotations(%{datatypes: [], defaults: [], groups: [], table: []})
    |> parse_rows()
  end
end
