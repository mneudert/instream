defmodule Instream.Log.DefaultLogger do
  @moduledoc """
  Default logger for all entries.
  """

  require Logger

  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry

  @doc """
  Logs a request.
  """
  @spec log(Instream.Connection.log_entry) :: Instream.Connection.log_entry
  def log(%PingEntry{} = entry) do
    Logger.debug fn ->
      [ "[ping ", entry.host, "] ", to_string(entry.result) ]
    end

    entry
  end

  def log(%QueryEntry{} = entry) do
    Logger.debug fn ->
      [ "[query] ", entry.query ]
    end

    entry
  end

  def log(%StatusEntry{} = entry) do
    Logger.debug fn ->
      [ "[status ", entry.host, "] ", to_string(entry.result) ]
    end

    entry
  end

  def log(%WriteEntry{} = entry) do
    Logger.debug fn ->
      [ "[write] ", to_string(entry.points), " points" ]
    end

    entry
  end
end
