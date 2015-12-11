defmodule Instream.Encoder.InfluxQL do
  @moduledoc """
  Encoder module for InfluxQL.
  """

  alias Instream.Query.Builder

  @doc """
  Converts a query builder struct to InfluxQL.
  """
  @spec encode(Builder.t) :: String.t
  def encode(query) do
    select(query)
    |> append_from(query)
    |> append_where(query)
  end

  @doc """
  Quotes a value in a query.

  ## Examples

      iex> quote_value(100)
      "100"

      iex> quote_value(:foo)
      "foo"

      iex> quote_value("stringy")
      "'stringy'"
  """
  @spec quote_value(any) :: String.t
  def quote_value(value) when is_binary(value), do: "'#{ value }'"
  def quote_value(value),                       do: to_string(value)


  # Internal methods

  defp append_from(str, query) do
    str <> " FROM " <> query.from
  end

  defp append_where(str, %{ where: fields }) when fields == %{}, do: str
  defp append_where(str, %{ where: fields }) do
    where =
         fields
      |> Map.keys()
      |> Enum.map(fn (field) ->
           to_string(field) <> " = " <> quote_value(fields[field])
         end)
      |> Enum.join(" AND ")

    str <> " WHERE " <> where
  end

  defp encode_select(%{ select: select }) when is_binary(select), do: select
  defp encode_select(%{ select: select }) when is_list(select)    do
    select |> Enum.join(", ")
  end

  defp select(query) do
    "SELECT " <> encode_select(query)
  end
end
