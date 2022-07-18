defmodule Instream.Log.DefaultLogger do
  @moduledoc """
  Default logger for all entries.
  """

  require Logger

  alias Instream.Connection.JSON
  alias Instream.Log.DeleteEntry
  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry

  @doc """
  Logs a request.
  """
  @spec log(Instream.Connection.log_entry()) :: Instream.Connection.log_entry()
  def log(%PingEntry{} = entry) do
    _ =
      Logger.debug(
        ["[ping ", entry.host, "] ", to_string(entry.result)],
        metadata(entry)
      )

    entry
  end

  def log(%QueryEntry{} = entry) do
    _ =
      Logger.debug(
        ["[query] ", InfluxQL.Sanitize.redact_passwords(entry.query)],
        metadata(entry)
      )

    entry
  end

  def log(%StatusEntry{} = entry) do
    _ =
      Logger.debug(
        ["[status ", entry.host, "] ", to_string(entry.result)],
        metadata(entry)
      )

    entry
  end

  def log(%WriteEntry{} = entry) do
    _ =
      Logger.debug(
        ["[write] ", to_string(entry.points), " points"],
        metadata(entry)
      )

    entry
  end

  def log(%DeleteEntry{} = entry) do
    {conn, entry} = Map.pop!(entry, :conn)

    _ = Logger.debug(["[delete] ", JSON.encode(entry.payload, conn), " predicate"])

    entry
  end

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
