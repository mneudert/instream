defmodule Instream.Query.Write do
  @moduledoc """
  Executes `:write` queries..
  """

  use Instream.Query

  def execute(%Query{} = query, opts, conn) do
    query
    |> conn[:writer].write(opts, conn)
    |> maybe_parse(opts)
  end
end
