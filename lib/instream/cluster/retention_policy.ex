defmodule Instream.Cluster.RetentionPolicy do
  @moduledoc """
  Retention policy administration helper.
  """

  alias Instream.Query
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
  @spec create(String.t, String.t, String.t) :: Query.t
  def create(name, database, policy) do
    Validate.database! database

    %Query{
      payload: "CREATE RETENTION POLICY #{ name } ON #{ database } #{ policy }",
      type:    :read
    }
  end

  @doc """
  Returns a query to drop a retention policy.
  """
  @spec drop(String.t, String.t) :: Query.t
  def drop(name, database) do
    Validate.database! database

    %Query{
      payload: "DROP RETENTION POLICY #{ name } ON #{ database }",
      type:    :read
    }
  end

  @doc """
  Returns a query to list retention policies.
  """
  @spec show(String.t) :: Query.t
  def show(database) do
    Validate.database! database

    %Query{
      payload: "SHOW RETENTION POLICIES ON #{ database }",
      type:    :read
    }
  end
end
