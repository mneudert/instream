defmodule Instream.Query.Builder do
  @moduledoc """
  Query Builder.
  """

  defstruct [
    from:   nil,
    select: "*",
    where:  %{}
  ]

  @opaque t :: %__MODULE__{}


  @doc """
  Builds a `FROM` query expression.
  """
  @spec from(String.t) :: t
  def from(expr) do
    %__MODULE__{ from: expr }
  end

  @doc """
  Builds a `SELECT` query expression.
  """
  @spec select(t, String.t) :: t
  def select(query, expr \\ "*") do
    %{ query | select: expr }
  end

  @doc """
  Builds a `WHERE` query expression.
  """
  @spec where(t, map) :: t
  def where(query, fields) do
    %{ query | where: fields }
  end
end
