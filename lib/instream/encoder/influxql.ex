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
    "SELECT #{ encode_select(query) } FROM #{ query.from }"
  end


  # Internal methods

  defp encode_select(%{ select: select }) when is_binary(select), do: select
  defp encode_select(%{ select: select }) when is_list(select)    do
    select |> Enum.join(", ")
  end
end
