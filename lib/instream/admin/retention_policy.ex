defmodule Instream.Admin.RetentionPolicy do
  @moduledoc """
  Retention policy administration helper.
  """

  alias Instream.Query
  alias Instream.Validate

  @doc """
  Returns a query to create a retention policy.
  """
  @spec create(name     :: String.t,
               database :: String.t,
               policy   :: String.t) :: Query.t
  def create(name, database, policy) do
    Validate.database! database

    %Query{
      payload: "CREATE RETENTION POLICY #{ name } ON #{ database } #{ policy }",
      type:    :host
    }
  end

  @doc """
  Returns a query to drop a retention policy.
  """
  @spec drop(name :: String.t, database :: String.t) :: Query.t
  def drop(name, database) do
    Validate.database! database

    %Query{
      payload: "DROP RETENTION POLICY #{ name } ON #{ database }",
      type:    :host
    }
  end

  @doc """
  Returns a query to list retention policies.
  """
  @spec show(database :: String.t) :: Query.t
  def show(database) do
    Validate.database! database

    %Query{
      payload: "SHOW RETENTION POLICIES #{ database }",
      type:    :host
    }
  end
end
