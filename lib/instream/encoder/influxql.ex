defmodule Instream.Encoder.InfluxQL do
  @moduledoc """
  Encoder module for InfluxQL.
  """

  alias Instream.Query.Builder

  @doc """
  Converts a query builder struct to InfluxQL.
  """
  @spec encode(Builder.t) :: String.t
  def encode(%{ command: "CREATE DATABASE" } = query) do
    query.command
    |> append_if_not_exists(get_argument(query, :if_not_exists, false))
    |> append_binary(get_argument(query, :database))
  end

  def encode(%{ command: "DROP DATABASE" } = query) do
    query.command
    |> append_binary(get_argument(query, :database))
  end

  def encode(%{ command: "SELECT" } = query) do
    query.command
    |> append_binary(encode_select(get_argument(query, :select)))
    |> append_from(get_argument(query, :from))
    |> append_where(get_argument(query, :where))
  end

  def encode(%{ command: "SHOW" } = query) do
    query.command
    |> append_binary(get_argument(query, :show))
    |> append_on(get_argument(query, :on))
  end

  @doc """
  Quotes an identifier if necessary.

  ## Examples

      iex> quote_identifier("unquoted")
      "unquoted"

      iex> quote_identifier("_unquoted")
      "_unquoted"

      iex> quote_identifier("100quotes")
      "\\"100quotes\\""

      iex> quote_identifier("quotes for whitespace")
      "\\"quotes for whitespace\\""

      iex> quote_identifier("dáshes-and.stüff")
      "\\"dáshes-and.stüff\\""
  """
  @spec quote_identifier(any) :: String.t
  def quote_identifier(ident) when is_binary(ident) do
    case Regex.match?(~r/(^[0-9]|[^a-zA-Z0-9_])/, ident) do
      false -> ident
      true  -> "\"#{ ident }\""
    end
  end

  def quote_identifier(ident), do: ident |> to_string() |> quote_identifier()

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

  defp append_binary(str, append) do
    "#{ str } #{ append }"
  end

  defp append_from(str, from) do
    str <> " FROM " <> from
  end

  defp append_if_not_exists(str, false), do: str
  defp append_if_not_exists(str, true)   do
    "#{ str } IF NOT EXISTS"
  end

  defp append_on(str, nil),      do: str
  defp append_on(str, database), do: "#{ str } ON #{ database }"

  defp append_where(str, nil),   do: str
  defp append_where(str, fields) do
    where =
         fields
      |> Map.keys()
      |> Enum.map(fn (field) ->
           quote_identifier(field) <> " = " <> quote_value(fields[field])
         end)
      |> Enum.join(" AND ")

    str <> " WHERE " <> where
  end

  defp encode_select(select) when is_binary(select), do: select
  defp encode_select(select) when is_list(select)    do
    select
    |> Enum.map( &quote_identifier/1 )
    |> Enum.join(", ")
  end


  # Utility methods

  defp get_argument(%{ arguments: args }, argument, default \\ nil) do
    Map.get(args, argument, default)
  end
end
