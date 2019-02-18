defmodule Instream.Admin.Stats do
  @moduledoc false

  alias Instream.Query.Builder

  @doc """
  Returns a query to retrieve server stats.
  """
  @spec show() :: Builder.t()
  def show, do: Builder.show(:stats)
end
