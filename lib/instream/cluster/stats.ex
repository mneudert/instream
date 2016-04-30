defmodule Instream.Cluster.Stats do
  @moduledoc false

  alias Instream.Admin

  @doc false
  @spec show() :: Builder.t
  def show() do
    warn()
    Admin.Stats.show()
  end


  defp warn do
    IO.write :stderr, "warning: Instream.Cluster.Stats has been renamed" <>
                      " to Instream.Admin.Stats. This module will be" <>
                      " removed in an upcoming release\n" <>
                      Exception.format_stacktrace
  end
end
