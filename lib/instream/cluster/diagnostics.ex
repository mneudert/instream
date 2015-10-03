defmodule Instream.Cluster.Diagnostics do
  @moduledoc """
  Diagnostics query helper.
  """

  alias Instream.Query

  @doc """
  Returns a query to retrieve server diagnostics.
  """
  @spec show() :: Query.t
  def show() do
    %Query{
      payload: "SHOW DIAGNOSTICS",
      type:    :cluster
    }
  end
end
