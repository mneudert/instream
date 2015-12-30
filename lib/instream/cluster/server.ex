defmodule Instream.Cluster.Server do
  @moduledoc """
  Server administration helper.
  """

  alias Instream.Query

  @doc """
  Returns a query to list servers.
  """
  @spec show() :: Query.t
  def show() do
    %Query{
      payload: "SHOW SERVERS",
      type:    :read
    }
  end
end
