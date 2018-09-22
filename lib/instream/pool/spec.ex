defmodule Instream.Pool.Spec do
  @moduledoc false

  alias Instream.Pool

  @doc """
  Returns a supervisable pool child_spec.
  """
  @spec spec(module) :: Supervisor.Spec.spec()
  def spec(conn) do
    {pool_opts, worker_opts} = get_opts(conn)

    :poolboy.child_spec(conn, pool_opts, worker_opts)
  end

  defp get_opts(conn) do
    pool_opts =
      (conn.config([:pool]) || [])
      |> Keyword.take([:size, :max_overflow])
      |> Keyword.put(:name, {:local, conn.__pool__})
      |> Keyword.put(:worker_module, Pool.Worker)

    {pool_opts, %{module: conn}}
  end
end
