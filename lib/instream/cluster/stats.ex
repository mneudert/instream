defmodule Instream.Cluster.Stats do
  @moduledoc """
  Stats query helper.
  """

  alias Instream.Query.Builder

  @doc """
  Returns a query to retrieve server stats.
  """
  @spec show() :: Builder.t
  def show(), do: Builder.show(:stats)
end
