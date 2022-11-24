defmodule Instream.Writer.Line do
  @moduledoc """
  Point writer for the line protocol.

  Will use `Instream.Writer.LineV1` or `Instream.Writer.LineV2` depending
  on the connection version.

  Please refer to the writer appropriate to your configuration and/or version.
  """

  alias Instream.Writer.LineV1
  alias Instream.Writer.LineV2

  @behaviour Instream.Writer

  @impl Instream.Writer
  def write(points, opts, conn) do
    case conn.config(:version) do
      :v1 -> LineV1.write(points, opts, conn)
      :v2 -> LineV2.write(points, opts, conn)
    end
  end
end
