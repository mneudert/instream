defmodule Instream.Cluster.Database do
  @moduledoc """
  Database administration helper.
  """

  alias Instream.Query
  alias Instream.Validate

  @doc """
  Returns a query to create a database.

  Options:

  - `:if_not_exists` - setting to `true` appends "IF NOT EXISTS" to the query.
  """
  @spec create(String.t, Keyword.t) :: Query.t
  def create(database, opts \\ []) do
    Validate.database! database

    payload = case opts[:if_not_exists] do
      true -> "CREATE DATABASE IF NOT EXISTS #{ database }"
      _    -> "CREATE DATABASE #{ database }"
    end

    %Query{
      payload: payload,
      type:    :cluster
    }
  end

  @doc """
  Returns a query to drop a database.
  """
  @spec drop(String.t) :: Query.t
  def drop(database) do
    Validate.database! database

    %Query{
      payload: "DROP DATABASE #{ database }",
      type:    :cluster
    }
  end

  @doc """
  Returns a query to list databases.
  """
  @spec show() :: Query.t
  def show() do
    %Query{
      payload: "SHOW DATABASES",
      type:    :cluster
    }
  end
end
