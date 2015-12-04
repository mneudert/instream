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
    "SELECT #{ query.select } FROM #{ query.from }"
  end
end
