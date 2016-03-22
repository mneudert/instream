defmodule Instream.Writer.JSON do
  @moduledoc """
  Point writer for the JSON protocol.
  """

  use Instream.Writer

  alias Instream.Query.Headers
  alias Instream.Query.URL


  def write(query, opts, conn) do
    headers = Headers.assemble(conn) ++ [{ 'Content-Type', 'application/json' }]
    payload = query.payload |> rename_timestamp_field() |> Poison.encode!
    url     =
         conn
      |> URL.write()
      |> URL.append_database(opts[:database])

    http_opts = Keyword.get(conn, :http_opts, [])

    { :ok, status, headers, client } = :hackney.post(url, headers, payload, http_opts)
    { :ok, response }                = :hackney.body(client)

    { status, headers, response }
  end


  # rename "timestamp" field of points to "time".
  # necessary evil until the json writer is removed.
  defp rename_timestamp_field(%{ points: points } = payload) do
    points = Enum.map points, fn (point) ->
      point
      |> Map.put(:time, Map.get(point, :timestamp, nil))
      |> Map.delete(:timestamp)
    end

    %{ payload | points: points }
  end
end
