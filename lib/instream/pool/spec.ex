defmodule Instream.Pool.Spec do
  @moduledoc """
  Connection pool specification helper.
  """

  alias Instream.Pool

  @doc """
  Returns a supervisable pool child_spec.
  """
  @spec spec(module) :: Supervisor.Spec.spec
  def spec(conn) do
    { pool_opts, worker_opts } = get_opts(conn)

    :poolboy.child_spec(conn, pool_opts, worker_opts)
  end

  defp get_opts(conn) do
    { pool_opts,
      worker_opts } = Keyword.split(conn.config, [ :pool ])

    pool_opts = pool_opts[:pool] || []
    pool_opts =
         pool_opts
      |> Keyword.put_new(:max_overflow, 10)
      |> Keyword.put_new(:size, 5)

    pool_opts =
         pool_opts
      |> Keyword.put(:name, { :local, conn.__pool__ })
      |> Keyword.put(:worker_module, Pool.Worker)

    worker_opts = worker_opts |> Keyword.put(:module, conn)

    { pool_opts, worker_opts }
  end
end
