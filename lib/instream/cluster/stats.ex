defmodule Instream.Cluster.Stats do
  @moduledoc """
  Stats query helper.
  """

  alias Instream.Query

  @doc """
  Returns a query to retrieve server stats.
  """
  @spec show() :: Query.t
  def show() do
    %Query{
      payload: "SHOW STATS",
      type:    :cluster
    }
  end
end
