defmodule Instream.Decoder.CSV do
  @moduledoc false

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

  defp parse_datatypes({{field, "double"}, value}), do: {field, String.to_float(value)}
  defp parse_datatypes({{field, "long"}, value}), do: {field, String.to_integer(value)}
  defp parse_datatypes({{field, _}, value}), do: {field, value}

  defp parse_table(table) do
    case __MODULE__.Parser.parse_string(table, skip_headers: false) do
      [["#datatype" | _ = datatypes], ["" | _ = headers] | [_ | _] = rows] ->
        Enum.map(rows, fn ["" | row] ->
          headers
          |> Enum.zip(datatypes)
          |> Enum.zip(row)
          |> Enum.map(&parse_datatypes/1)
          |> Map.new()
        end)

      [["#datatype" | _ = datatypes], [_ | _] = headers | [_ | _] = rows] ->
        Enum.map(rows, fn row ->
          headers
          |> Enum.zip(datatypes)
          |> Enum.zip(row)
          |> Enum.map(&parse_datatypes/1)
          |> Map.new()
        end)

      [["" | _ = headers] | [_ | _] = rows] ->
        Enum.map(rows, fn ["" | row] -> headers |> Enum.zip(row) |> Map.new() end)

      [[_ | _] = headers | [_ | _] = rows] ->
        Enum.map(rows, fn row -> headers |> Enum.zip(row) |> Map.new() end)

      _ ->
        []
    end
  end
end
