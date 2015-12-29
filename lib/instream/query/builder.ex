defmodule Instream.Query.Builder do
  @moduledoc """
  Query Builder.
  """

  defstruct [
    from:   nil,
    select: "*",
    show:   nil,
    where:  %{}
  ]

  @opaque t :: %__MODULE__{}


  @doc """
  Builds a `FROM` query expression.
  """
  @spec from(String.t | atom) :: t
  def from(series) when is_atom(series) do
    %__MODULE__{ from: series.__meta__(:measurement) }
  end

  def from(measurement) when is_binary(measurement) do
    %__MODULE__{ from: measurement }
  end

  @doc """
  Builds a `SELECT` query expression.
  """
  @spec select(t, String.t) :: t
  def select(query, expr \\ "*") do
    %{ query | select: expr }
  end

  @doc """
  Build a `SHOW` query expression.
  """
  @spec show(atom) :: t
  def show(what) do
    %__MODULE__{ show: what |> Atom.to_string() |> String.upcase() }
  end

  @doc """
  Builds a `WHERE` query expression.
  """
  @spec where(t, map) :: t
  def where(query, fields) do
    %{ query | where: fields }
  end
end
