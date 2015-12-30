defmodule Instream.Cluster.Server do
  @moduledoc """
  Server administration helper.
  """

  alias Instream.Query.Builder

  @doc """
  Returns a query to list servers.
  """
  @spec show() :: Builder.t
  def show(), do: Builder.show(:servers)
end
