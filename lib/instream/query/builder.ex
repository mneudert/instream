defmodule Instream.Query.Builder do
  @moduledoc """
  Query Builder.
  """

  defstruct [
    command:   nil,
    arguments: %{}
  ]

  @opaque t :: %__MODULE__{}

  @doc """
  Builds a `CREATE DATABASE` query expression.
  """
  @spec create_database(String.t) :: t
  def create_database(name) do
    %__MODULE__{}
    |> set_command("CREATE DATABASE")
    |> set_argument(:database, name)
  end

  @doc """
  Builds a `DROP DATABASE` query expression.
  """
  @spec drop_database(String.t) :: t
  def drop_database(name) do
    %__MODULE__{}
    |> set_command("DROP DATABASE")
    |> set_argument(:database, name)
  end

  @doc """
  Builds a `FROM` query expression.
  """
  @spec from(String.t | atom) :: t
  def from(series) when is_atom(series) do
    from(series.__meta__(:measurement))
  end

  def from(measurement) when is_binary(measurement) do
    %__MODULE__{}
    |> set_command("SELECT")
    |> set_argument(:from, measurement)
    |> set_argument(:select, "*")
  end

  @doc """
  Builds a `SELECT` query expression.
  """
  @spec select(t, String.t) :: t
  def select(query, expr \\ "*"), do: set_argument(query, :select, expr)

  @doc """
  Build a `SHOW` query expression.
  """
  @spec show(atom) :: t
  def show(what) do
    %__MODULE__{}
    |> set_command("SHOW")
    |> set_argument(:show, what |> Atom.to_string() |> String.upcase())
  end

  @doc """
  Builds a `WHERE` query expression.
  """
  @spec where(t, map) :: t
  def where(query, fields), do: set_argument(query, :where, fields)


  # Internal methods

  defp set_argument(%{ arguments: args } = query, key, val) do
    %{ query | arguments: Map.put(args, key, val) }
  end

  defp set_command(query, command), do: %{ query | command: command }
end
