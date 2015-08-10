defmodule Instream.Query.Write do
  @moduledoc """
  Executes `:write` queries..
  """

  use Instream.Query

  def execute(%Query{ payload: payload }, opts, conn) do
    payload
    |> conn[:writer].write(opts, conn)
    |> maybe_parse(opts)
  end
end
