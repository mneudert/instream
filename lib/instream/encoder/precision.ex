defmodule Instream.Encoder.Precision do
  @moduledoc """
  Encoder module for precision values.

  Converts a __MODULE__.t type precision atom to its binary counterpart.
  """

  @type t ::
          :hour
          | :minute
          | :second
          | :millisecond
          | :microsecond
          | :nanosecond
          | :rfc3339
          | t_deprecated

  @type t_deprecated ::
          :hours
          | :minutes
          | :seconds
          | :milliseconds
          | :microseconds
          | :nanoseconds
          | :milli_seconds
          | :micro_seconds
          | :nano_seconds

  @doc """
  Converts a precision atom to its binary identifier.
  """
  @spec encode(t) :: String.t()
  def encode(:hour), do: "h"
  def encode(:minute), do: "m"
  def encode(:second), do: "s"
  def encode(:millisecond), do: "ms"
  def encode(:microsecond), do: "u"
  def encode(:nanosecond), do: "n"
  def encode(:rfc3339), do: ""

  # deprecated time units

  def encode(:hours), do: "h"
  def encode(:minutes), do: "m"
  def encode(:seconds), do: "s"
  def encode(:milliseconds), do: "ms"
  def encode(:microseconds), do: "u"
  def encode(:nanoseconds), do: "n"

  def encode(:milli_seconds), do: "ms"
  def encode(:micro_seconds), do: "u"
  def encode(:nano_seconds), do: "n"
end
