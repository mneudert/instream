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
  @spec log(Instream.Connection.log_entry()) :: Instream.Connection.log_entry()
  def log(%PingEntry{} = entry) do
    Logger.debug(
      fn ->
        ["[ping ", entry.host, "] ", to_string(entry.result)]
      end,
      metadata(entry)
    )

    entry
  end

  def log(%QueryEntry{} = entry) do
    Logger.debug(
      fn ->
        ["[query] ", InfluxQL.Sanitize.redact_passwords(entry.query)]
      end,
      metadata(entry)
    )

    entry
  end

  def log(%StatusEntry{} = entry) do
    Logger.debug(
      fn ->
        ["[status ", entry.host, "] ", to_string(entry.result)]
      end,
      metadata(entry)
    )

    entry
  end

  def log(%WriteEntry{} = entry) do
    Logger.debug(
      fn ->
        ["[write] ", to_string(entry.points), " points"]
      end,
      metadata(entry)
    )

    entry
  end

  # Utility methods

  @doc false
  def metadata(%{metadata: metadata}) do
    # method is public to avoid compiler notices about this method
    # being unused when combined with a logger compile time purge level
    # removing the `Logger.debug/2` calls.
    metadata
    |> Map.delete(:__struct__)
    |> Keyword.new()
  end
end
