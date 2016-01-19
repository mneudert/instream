defmodule Instream.Cluster.RetentionPolicy do
  @moduledoc """
  Retention policy administration helper.
  """

  alias Instream.Query
  alias Instream.Query.Builder
  alias Instream.Validate

  @doc """
  Returns a query to alter a retention policy.
  """
  @spec alter(String.t, String.t, String.t) :: Query.t
  def alter(name, database, policy) do
    Validate.database! database

    %Query{
      payload: "ALTER RETENTION POLICY #{ name } ON #{ database } #{ policy }",
      type:    :read
    }
  end

  @doc """
  Returns a query to create a retention policy.
  """
  @spec create(String.t, String.t, String.t, pos_integer, boolean) :: Query.t
  def create(name, database, duration, replication, default \\ false) do
    Validate.database! database

    name
    |> Builder.create_retention_policy()
    |> Builder.on(database)
    |> Builder.duration(duration)
    |> Builder.replication(replication)
    |> Builder.default(default)
  end

  @doc """
  Returns a query to drop a retention policy.
  """
  @spec drop(String.t, String.t) :: Builder.t
  def drop(name, database) do
    Validate.database! database

    name
    |> Builder.drop_retention_policy()
    |> Builder.on(database)
  end

  @doc """
  Returns a query to list retention policies.
  """
  @spec show(String.t) :: Builder.t
  def show(database) do
    Validate.database! database

    :retention_policies
    |> Builder.show()
    |> Builder.on(database)
  end
end
