defmodule Instream.Decoder.RFC3339 do
  @moduledoc false

  @doc """
  Converts an RFC3339 formatted date string to nanoseconds.

  OTP versions earlier than `21.0` are cut off to microsecond precision!
  """
  @spec to_nanosecond(binary) :: non_neg_integer | nil
  def to_nanosecond(time)

  if Code.ensure_loaded?(:calendar) && function_exported?(:calendar, :rfc3339_to_system_time, 2) do
    def to_nanosecond(time) when is_binary(time) do
      time
      |> String.to_charlist()
      |> :calendar.rfc3339_to_system_time(unit: :nanosecond)
    rescue
      _ -> nil
    end
  else
    def to_nanosecond(time) when is_binary(time) do
      case DateTime.from_iso8601(time) do
        {:ok, datetime, 0} -> DateTime.to_unix(datetime, :nanosecond)
        _ -> nil
      end
    end
  end
end
