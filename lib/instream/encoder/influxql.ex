defmodule Instream.Encoder.InfluxQL do
  @moduledoc """
  Encoder module for InfluxQL.
  """

  alias Instream.Query.Builder

  @doc """
  Converts a query builder struct to InfluxQL.
  """
  @spec encode(Builder.t) :: String.t
  def encode(%Builder{ command: "CREATE" } = query) do
    encode_create(get_argument(query, :what), query)
  end

  def encode(%Builder{ command: "DROP" } = query) do
    encode_drop(get_argument(query, :what), query)
  end

  def encode(%Builder{ command: "SELECT" } = query) do
    query.command
    |> append_binary(encode_select(get_argument(query, :select)))
    |> append_from(get_argument(query, :from))
    |> append_where(get_argument(query, :where))
    |> append_limit(get_argument(query, :limit))
    |> append_offset(get_argument(query, :offset))
  end

  def encode(%Builder{ command: "SHOW" } = query) do
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
  @spec quote_identifier(String.t) :: String.t
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


  # Extended command creation

  defp encode_create("DATABASE", query) do
    query.command
    |> append_binary(get_argument(query, :what))
    |> append_if_not_exists(get_argument(query, :if_not_exists, false))
    |> append_binary(get_argument(query, :database))
  end

  defp encode_create("RETENTION POLICY", query) do
    query.command
    |> append_binary(get_argument(query, :what))
    |> append_binary(get_argument(query, :policy))
    |> append_on(get_argument(query, :on))
    |> append_duration(get_argument(query, :duration))
    |> append_replication(get_argument(query, :replication))
    |> append_default(get_argument(query, :default, false))
  end


  defp encode_drop("DATABASE", query) do
    query.command
    |> append_binary(get_argument(query, :what))
    |> append_binary(get_argument(query, :database))
  end

  defp encode_drop("RETENTION POLICY", query) do
    query.command
    |> append_binary(get_argument(query, :what))
    |> append_binary(get_argument(query, :policy))
    |> append_on(get_argument(query, :on))
  end


  # Internal methods

  defp append_binary(str, append), do: "#{ str } #{ append }"

  defp append_default(str, true),  do: "#{ str } DEFAULT"
  defp append_default(str, false), do: str

  defp append_duration(str, duration), do: "#{ str } DURATION #{ duration }"

  defp append_from(str, from), do: "#{ str } FROM #{ from }"

  defp append_if_not_exists(str, true),  do: "#{ str } IF NOT EXISTS"
  defp append_if_not_exists(str, false), do: str

  defp append_on(str, nil),      do: str
  defp append_on(str, database), do: "#{ str } ON #{ database }"

  defp append_replication(str, num) do
    "#{ str } REPLICATION #{ num |> Integer.to_string(10) }"
  end

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

  defp append_limit(str, nil),   do: str
  defp append_limit(str, value), do: "#{str} LIMIT #{value}"

  defp append_offset(str, nil),   do: str
  defp append_offset(str, value), do: "#{str} OFFSET #{value}"

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
