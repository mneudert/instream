defmodule Instream.Writer.UDP do
  @moduledoc """
  Point writer for the line protocol using UDP.

  ## Configuration

  Write queries are run through a process pool having an additional timeout:

      config :my_app, MyConnection,
        pool: [max_overflow: 10, size: 5],
        pool_timeout: 500

  This configuration will be used to wait for an available worker
  to execute a query and defaults to `5_000`.

  ## Write Options

  - `async: true`: execute writes asynchronously
  """

  alias Instream.Encoder.Line, as: Encoder

  @behaviour :poolboy_worker
  @behaviour Instream.Writer

  @response {:ok, 200, [], ""}

  @impl Instream.Writer
  def writer_workers(conn) do
    pool_name = Module.concat(conn, UDPWriterPool)

    pool_opts =
      (conn.config(:pool) || [])
      |> Keyword.take([:size, :max_overflow])
      |> Keyword.put(:name, {:local, pool_name})
      |> Keyword.put(:worker_module, __MODULE__)

    [:poolboy.child_spec(conn, pool_opts, module: conn)]
  end

  @impl :poolboy_worker
  def start_link(default), do: GenServer.start_link(__MODULE__, default)

  @doc false
  def init(module: conn) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])

    {:ok, %{module: conn, udp_socket: socket}}
  end

  @doc false
  def terminate(_reason, %{udp_socket: socket}), do: :gen_udp.close(socket)

  @impl Instream.Writer
  def write(points, opts, conn) do
    default_pool_timeout = conn.config(:pool_timeout) || 5000

    pool_name = Module.concat(conn, UDPWriterPool)
    pool_timeout = opts[:pool_timeout] || default_pool_timeout

    worker = :poolboy.checkout(pool_name, pool_timeout)

    :ok =
      if opts[:async] do
        GenServer.cast(worker, {:write, points})
      else
        GenServer.call(worker, {:write, points}, :infinity)
      end

    :ok = :poolboy.checkin(pool_name, worker)

    @response
  end

  @doc false
  def handle_call({:write, points}, _from, state) do
    {:reply, do_write(points, state), state}
  end

  @doc false
  def handle_cast({:write, points}, state) do
    _ = do_write(points, state)

    {:noreply, state}
  end

  defp do_write([_ | _] = points, %{module: conn, udp_socket: udp_socket}) do
    config = conn.config()
    payload = Encoder.encode(points)

    :gen_udp.send(
      udp_socket,
      String.to_charlist(config[:host]),
      config[:port_udp],
      String.to_charlist(payload)
    )
  end

  defp do_write(_, _), do: :ok
end
