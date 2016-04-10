defmodule Instream.Log.DefaultLogger do
  @moduledoc """
  Default logger for all entries.
  """

  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry

  @doc """
  Logs a request.
  """
  @spec log(Instream.Connection.log_entry) :: Instream.Connection.log_entry
  def log(%PingEntry{} = entry), do: entry
  def log(%QueryEntry{} = entry), do: entry
  def log(%StatusEntry{} = entry), do: entry
  def log(%WriteEntry{} = entry), do: entry
end
