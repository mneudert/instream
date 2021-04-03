defmodule Instream.Decoder.CSV do
  @moduledoc false

  NimbleCSV.define(__MODULE__.Parser, separator: ",", escape: "\"")

  @doc """
  Converts a full CSV response into a list of maps.
  """
  @spec parse(binary) :: [map]
  def parse(response) do
    case __MODULE__.Parser.parse_string(response, skip_headers: false) do
      [["" | _ = headers] | [_ | _] = rows] ->
        Enum.map(rows, fn ["" | row] -> headers |> Enum.zip(row) |> Map.new() end)

      [[_ | _] = headers | [_ | _] = rows] ->
        Enum.map(rows, fn row -> headers |> Enum.zip(row) |> Map.new() end)

      _ ->
        []
    end
  end
end
