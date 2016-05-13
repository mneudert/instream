defmodule Instream.Query.Builder do
  @moduledoc """
  Query Builder.
  """

  defstruct [
    command:   nil,
    arguments: %{}
  ]

  @opaque t :: %__MODULE__{}


  @what_map [
    database:           "DATABASE",
    databases:          "DATABASES",
    diagnostics:        "DIAGNOSTICS",
    measurements:       "MEASUREMENTS",
    retention_policies: "RETENTION POLICIES",
    retention_policy:   "RETENTION POLICY",
    stats:              "STATS"
  ]


  @doc """
  Builds a `CREATE DATABASE` query expression.
  """
  @spec create_database(String.t) :: t
  def create_database(name) do
    %__MODULE__{}
    |> set_command("CREATE")
    |> set_argument(:database, name)
    |> set_argument(:method, :post)
    |> set_argument(:what, @what_map[:database])
  end

  @doc """
  Builds a `CREATE RETENTION POLICY` query expression.
  """
  @spec create_retention_policy(String.t) :: t
  def create_retention_policy(name) do
    %__MODULE__{}
    |> set_command("CREATE")
    |> set_argument(:method, :post)
    |> set_argument(:policy, name)
    |> set_argument(:what, @what_map[:retention_policy])
  end

  @doc """
  Sets the `DEFAULT` flag for queries supporting it.
  """
  @spec default(t, boolean) :: t
  def default(query, default \\ true) do
    set_argument(query, :default, default)
  end

  @doc """
  Builds a `DROP DATABASE` query expression.
  """
  @spec drop_database(String.t) :: t
  def drop_database(name) do
    %__MODULE__{}
    |> set_command("DROP")
    |> set_argument(:database, name)
    |> set_argument(:method, :post)
    |> set_argument(:what, @what_map[:database])
  end

  @doc """
  Builds a `DROP RETENTION POLICY` query expression.
  """
  @spec drop_retention_policy(String.t) :: t
  def drop_retention_policy(name) do
    %__MODULE__{}
    |> set_command("DROP")
    |> set_argument(:method, :post)
    |> set_argument(:policy, name)
    |> set_argument(:what, @what_map[:retention_policy])
  end

  @doc """
  Sets the `DURATION` argument for queries supporting it.
  """
  @spec duration(t, String.t) :: t
  def duration(query, expr), do: set_argument(query, :duration, expr)

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
  Sets the `IF NOT EXISTS` flag for queries supporting it.
  """
  @spec if_not_exists(t, boolean) :: t
  def if_not_exists(query, if_not_exists \\ true)

  def if_not_exists(query, false), do: query
  def if_not_exists(query, true)   do
    IO.write :stderr, "warning: Instream.Query.Builder.if_not_exists/1,2 is" <>
                      " deprecated and ignored by InfluxDB v0.10.0 onwards." <>
                      "\n" <> Exception.format_stacktrace

    set_argument(query, :if_not_exists, true)
  end

  @doc """
  Builds a `SELECT` query expression.
  """
  @spec select(t, String.t) :: t
  def select(query, expr \\ "*"), do: set_argument(query, :select, expr)

  @doc """
  Sets the `ON` argument for queries supporting it.
  """
  @spec on(t, String.t) :: t
  def on(query, database), do: set_argument(query, :on, database)

  @doc """
  Sets the `REPLICATION` argument for queries supporting it.
  """
  @spec replication(t, pos_integer) :: t
  def replication(query, num), do: set_argument(query, :replication, num)

  @doc """
  Build a `SHOW` query expression.
  """
  @spec show(atom) :: t
  def show(what) do
    %__MODULE__{}
    |> set_command("SHOW")
    |> set_argument(:show, @what_map[what])
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
