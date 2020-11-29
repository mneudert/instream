defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.

  ## Configuration

  Write queries are run through a process pool having an additional timeout:

      config :my_app, MyApp.MyConnection,
        pool: [max_overflow: 10, size: 5],
        pool_timeout: 500

  This configuration will be used to wait for an available worker
  to execute a query and defaults to `5_000`.

  ## Additional Write Options

  - `async: true`: execute writes asynchronously
  """

  alias Instream.Encoder.Line, as: Encoder

  @behaviour :poolboy_worker
  @behaviour Instream.Writer

  @response {200, [], ""}

  def writer_workers(conn) do
    pool_name = Module.concat(conn, UDPWriterPool)

    pool_opts =
      (conn.config([:pool]) || [])
      |> Keyword.take([:size, :max_overflow])
      |> Keyword.put(:name, {:local, pool_name})
      |> Keyword.put(:worker_module, __MODULE__)

    [:poolboy.child_spec(conn, pool_opts, module: conn)]
  end

  @doc false
  def start_link(default), do: GenServer.start_link(__MODULE__, default)

  @doc false
  def init(module: conn) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])

    {:ok, %{module: conn, udp_socket: socket}}
  end

  @doc false
  def terminate(_reason, %{udp_socket: socket}), do: :gen_udp.close(socket)

  def write(query, opts, conn) do
    default_pool_timeout = conn.config([:pool_timeout]) || 5000

    pool_name = Module.concat(conn, UDPWriterPool)
    pool_timeout = opts[:pool_timeout] || default_pool_timeout

    worker = :poolboy.checkout(pool_name, pool_timeout)

    if opts[:async] do
      :ok = GenServer.cast(worker, {:execute, query, opts})
    else
      _ = GenServer.call(worker, {:execute, query, opts}, :infinity)
    end

    :ok = :poolboy.checkin(pool_name, worker)

    @response
  end

  def handle_call({:execute, query, _opts}, _from, state) do
    {:reply, do_write(query, state), state}
  end

  def handle_cast({:execute, query, _opts}, state) do
    _ = do_write(query, state)

    {:noreply, state}
  end

  defp do_write(%{payload: %{points: [_ | _] = points}}, %{module: conn, udp_socket: udp_socket}) do
    config = conn.config()
    payload = Encoder.encode(points)

    :ok =
      :gen_udp.send(
        udp_socket,
        String.to_charlist(config[:host]),
        config[:port_udp],
        String.to_charlist(payload)
      )

    @response
  end

  defp do_write(_, _), do: @response
end
