defmodule Instream.Cluster.Database do
  @moduledoc """
  Database administration helper.
  """

  alias Instream.Query.Builder
  alias Instream.Validate

  @doc """
  Returns a query to create a database.

  Options:

  - `:if_not_exists` - setting to `true` appends "IF NOT EXISTS" to the query.
  """
  @spec create(String.t, Keyword.t) :: Builder.t
  def create(database, opts \\ []) do
    database
    |> Validate.database!
    |> Builder.create_database()
    |> Builder.if_not_exists(opts[:if_not_exists] || false)
  end

  @doc """
  Returns a query to drop a database.
  """
  @spec drop(String.t) :: Builder.t
  def drop(database) do
    database
    |> Validate.database!
    |> Builder.drop_database()
  end

  @doc """
  Returns a query to list databases.
  """
  @spec show() :: Builder.t
  def show(), do: Builder.show(:databases)
end
