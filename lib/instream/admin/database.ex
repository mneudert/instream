defmodule Instream.Admin.Database do
  @moduledoc """
  Database administration helper.
  """

  alias Instream.Query
  alias Instream.Validate

  @doc """
  Returns a query to create a database.
  """
  @spec create(database :: String.t) :: Query.t
  def create(database) do
    Validate.database! database

    %Query{
      query: "CREATE DATABASE #{ database }",
      type:  :query
    }
  end

  @doc """
  Returns a query to drop a database.
  """
  @spec drop(database :: String.t) :: Query.t
  def drop(database) do
    Validate.database! database

    %Query{
      query: "DROP DATABASE #{ database }",
      type:  :query
    }
  end

  @doc """
  Returns a query to list databases.
  """
  @spec show() :: Query.t
  def show() do
    %Query{
      query: "SHOW DATABASES",
      type:  :query
    }
  end
end
