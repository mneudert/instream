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

  defp parse_table(table) do
    case __MODULE__.Parser.parse_string(table, skip_headers: false) do
      [["" | _ = headers] | [_ | _] = rows] ->
        Enum.map(rows, fn ["" | row] -> headers |> Enum.zip(row) |> Map.new() end)

      [[_ | _] = headers | [_ | _] = rows] ->
        Enum.map(rows, fn row -> headers |> Enum.zip(row) |> Map.new() end)

      _ ->
        []
    end
  end
end
