defmodule Instream.Cluster.Database do
  @moduledoc """
  Database administration helper.
  """

  alias Instream.Query
  alias Instream.Validate

  @doc """
  Returns a query to create a database.
  """
  @spec create(String.t) :: Query.t
  def create(database) do
    Validate.database! database

    %Query{
      payload: "CREATE DATABASE #{ database }",
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
