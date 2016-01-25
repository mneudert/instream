defmodule Instream.Encoder.Precision do
  @moduledoc """
  Encoder module for precision values.

  Converts a __MODULE__.t type precision atom to its binary counterpart.
  """


  @type t :: :hours | :minutes | :seconds |
             :milli_seconds | :micro_seconds | :nano_seconds |
             :rfc3339


  @doc """
  Converts a precision atom to its binary identifier.
  """
  @spec encode(t) :: String.t
  def encode(:hours),         do: "h"
  def encode(:minutes),       do: "m"
  def encode(:seconds),       do: "s"
  def encode(:milli_seconds), do: "ms"
  def encode(:micro_seconds), do: "u"
  def encode(:nano_seconds),  do: "n"
  def encode(:rfc3339),       do: ""
end
