defmodule Instream.Admin.Database do
  @moduledoc false

  alias Instream.Query.Builder
  alias Instream.Validate

  @doc """
  Returns a query to create a database.
  """
  @spec create(String.t(), Keyword.t()) :: Builder.t()
  def create(database, _opts \\ []) do
    database
    |> Validate.database!()
    |> Builder.create_database()
  end

  @doc """
  Returns a query to drop a database.
  """
  @spec drop(String.t()) :: Builder.t()
  def drop(database) do
    database
    |> Validate.database!()
    |> Builder.drop_database()
  end

  @doc """
  Returns a query to list databases.
  """
  @spec show() :: Builder.t()
  def show, do: Builder.show(:databases)
end
