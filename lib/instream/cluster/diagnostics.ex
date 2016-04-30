defmodule Instream.Cluster.Diagnostics do
  @moduledoc false

  alias Instream.Admin

  @doc false
  @spec show() :: Builder.t
  def show() do
    warn()
    Admin.Diagnostics.show()
  end


  defp warn do
    IO.write :stderr, "warning: Instream.Cluster.Diagnostics has been" <>
                      " renamed to Instream.Admin.Diagnostics. This module" <>
                      " will be removed in an upcoming release\n" <>
                      Exception.format_stacktrace
  end
end
