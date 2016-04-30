defmodule Instream.Cluster.RetentionPolicy do
  @moduledoc false

  alias Instream.Admin

  @doc false
  @spec alter(String.t, String.t, String.t) :: Query.t
  def alter(name, database, policy) do
    warn()
    Admin.RetentionPolicy.alter(name, database, policy)
  end

  @doc false
  @spec create(String.t, String.t, String.t, pos_integer, boolean) :: Builder.t
  def create(name, database, duration, replication, default \\ false) do
    warn()
    Admin.RetentionPolicy.create(name, database, duration, replication, default)
  end

  @doc false
  @spec drop(String.t, String.t) :: Builder.t
  def drop(name, database) do
    warn()
    Admin.RetentionPolicy.drop(name, database)
  end

  @doc false
  @spec show(String.t) :: Builder.t
  def show(database) do
    warn()
    Admin.RetentionPolicy.show(database)
  end


  defp warn do
    IO.write :stderr, "warning: Instream.Cluster.RetentionPolicy has been" <>
                      " renamed to Instream.Admin.RetentionPolicy. This" <>
                      " module will be removed in an upcoming release\n" <>
                      Exception.format_stacktrace
  end
end
