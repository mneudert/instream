defmodule Instream.Admin.Diagnostics do
  @moduledoc """
  Diagnostics query helper.
  """

  alias Instream.Query.Builder

  @doc """
  Returns a query to retrieve server diagnostics.
  """
  @spec show() :: Builder.t
  def show(), do: Builder.show(:diagnostics)
end
