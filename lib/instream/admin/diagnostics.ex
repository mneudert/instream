defmodule Instream.Admin.Diagnostics do
  @moduledoc false

  alias Instream.Query.Builder

  @doc """
  Returns a query to retrieve server diagnostics.
  """
  @spec show() :: Builder.t()
  def show, do: Builder.show(:diagnostics)
end
