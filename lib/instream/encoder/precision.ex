defmodule Instream.Encoder.Precision do
  @moduledoc """
  Encoder module for precision values.

  Converts a __MODULE__.t type precision atom to its binary counterpart.
  """

  require Logger

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
  def encode(:nanosecond), do: "ns"
  def encode(:rfc3339), do: ""

  # deprecated time units

  def encode(:hours), do: warn_and_normalize(:hours, :hour)
  def encode(:minutes), do: warn_and_normalize(:minutes, :minute)
  def encode(:seconds), do: warn_and_normalize(:seconds, :second)
  def encode(:milliseconds), do: warn_and_normalize(:milliseconds, :millisecond)
  def encode(:microseconds), do: warn_and_normalize(:microseconds, :microsecond)
  def encode(:nanoseconds), do: warn_and_normalize(:nanoseconds, :nanosecond)

  def encode(:milli_seconds), do: warn_and_normalize(:milli_seconds, :millisecond)
  def encode(:micro_seconds), do: warn_and_normalize(:micro_seconds, :microsecond)
  def encode(:nano_seconds), do: warn_and_normalize(:nano_seconds, :nanosecond)

  defp warn_and_normalize(old, new) do
    Logger.info(fn -> "Deprecated precision: #{inspect(old)}, please use #{inspect(new)}" end)
    encode(new)
  end
end
