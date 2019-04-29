defmodule Instream.Encoder.Precision do
  @moduledoc false

  @type t ::
          :hour
          | :minute
          | :second
          | :millisecond
          | :microsecond
          | :nanosecond
          | :rfc3339

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
end
