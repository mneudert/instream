defmodule Instream.Cluster.Database do
  @moduledoc false

  alias Instream.Admin

  @doc false
  @spec create(String.t, Keyword.t) :: Builder.t
  def create(database, opts \\ []) do
    warn()
    Admin.Database.create(database, opts)
  end

  @doc false
  @spec drop(String.t) :: Builder.t
  def drop(database) do
    warn()
    Admin.Database.drop(database)
  end

  @doc false
  @spec show() :: Builder.t
  def show() do
    warn()
    Admin.Database.show()
  end


  defp warn do
    IO.write :stderr, "warning: Instream.Cluster.Database has been renamed" <>
                      " to Instream.Admin.Database. This module will be" <>
                      " removed in an upcoming release\n" <>
                      Exception.format_stacktrace
  end
end
