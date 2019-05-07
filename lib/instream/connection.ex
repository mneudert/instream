defmodule Instream.Connection do
  @moduledoc """
  Connection (pool) definition.

  All database connections will be made using a user-defined
  extension of this module.

  ## Example Module

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_application
      end

  ## Example Configuration

      config :my_application, MyConnection,
        auth:      [ method: :basic, username: "root", password: "root" ]
        host:      "influxdb.example.com",
        http_opts: [ insecure: true, proxy: "http://company.proxy" ],
        loggers:   [{ LogModule, :log_fun, [ :additional, :args ] }],
        pool:      [ max_overflow: 10, size: 5 ],
        port:      8086,
        scheme:    "http"
  """

  alias Instream.Log
  alias Instream.Query

  @type log_entry ::
          Log.PingEntry.t()
          | Log.QueryEntry.t()
          | Log.StatusEntry.t()
          | Log.WriteEntry.t()
  @type query_type :: Query.t() | String.t()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias Instream.Connection
      alias Instream.Connection.QueryPlanner
      alias Instream.Data
      alias Instream.Query

      @behaviour Connection

      @otp_app opts[:otp_app]
      @config opts[:config] || []

      loggers =
        @otp_app
        |> Connection.Config.compile_time(__MODULE__, @config)
        |> Keyword.get(:loggers, [])
        |> Enum.reduce(quote(do: entry), fn logger, acc ->
          {mod, fun, args} = logger

          quote do
            unquote(mod).unquote(fun)(unquote(acc), unquote_splicing(args))
          end
        end)

      def __log__(entry), do: unquote(loggers)

      def child_spec(_ \\ []) do
        Supervisor.Spec.supervisor(
          Instream.Connection.Supervisor,
          [__MODULE__],
          id: __MODULE__.Supervisor
        )
      end

      def config(keys \\ nil) do
        Connection.Config.runtime(@otp_app, __MODULE__, keys, @config)
      end

      # alias/convenience interface

      def ping(opts) when is_list(opts), do: ping(nil, opts)
      def status(opts) when is_list(opts), do: status(nil, opts)
      def version(opts) when is_list(opts), do: version(nil, opts)

      # public interface for usage

      def execute(query, opts \\ []), do: QueryPlanner.execute(query, opts, __MODULE__)

      def ping(host \\ nil, opts \\ []),
        do: execute(%Query{type: :ping, opts: [host: host]}, opts)

      def query(query, opts \\ []), do: execute(query, opts)

      def status(host \\ nil, opts \\ []),
        do: execute(%Query{type: :status, opts: [host: host]}, opts)

      def version(host \\ nil, opts \\ []),
        do: execute(%Query{type: :version, opts: [host: host]}, opts)

      def write(payload, opts \\ []) do
        database = Data.Write.determine_database(payload, opts)
        opts = Keyword.put(opts, :database, database)

        payload
        |> Data.Write.query(opts)
        |> execute(opts)
      end
    end
  end

  @doc """
  Sends a log entry to all configured loggers.
  """
  @callback __log__(log_entry) :: log_entry

  @doc """
  Returns a supervisable connection child_spec.
  """
  @callback child_spec(_ignored :: term) :: Supervisor.Spec.spec()

  @doc """
  Returns the connection configuration.
  """
  @callback config(keys :: nil | nonempty_list(term)) :: Keyword.t()

  @doc """
  Executes a query.

  Passing `[async: true]` in the options always returns :ok.
  The command will be executed asynchronously.
  """
  @callback execute(query :: query_type, opts :: Keyword.t()) :: any

  @doc """
  Pings a server.

  By default the first server in your connection configuration will be pinged.

  The server passed does not necessarily need to belong to your connection.
  Only the connection details (scheme, port, ...) will be used to determine
  the exact url to send the ping request to.
  """
  @callback ping(host :: String.t(), opts :: Keyword.t()) :: :pong | :error

  @doc """
  Executes a reading query.

  Options:

  - `method`: whether to use a "GET" or "POST" request (as atom)
  - `precision`: see `Instream.Encoder.Precision` for available values

  See `c:Instream.Connection.execute/2` for additional generic options.
  """
  @callback query(query :: String.t(), opts :: Keyword.t()) :: any

  @doc """
  Checks the status of a connection.
  """
  @callback status(opts :: Keyword.t()) :: :ok | :error

  @doc """
  Determines the version of an InfluxDB host.

  The version will be retrieved using a `:ping` query and extract the returned
  `X-Influxdb-Version` header. If the header is missing the version will be
  returned as `"unknown"`.
  """
  @callback version(host :: String.t(), opts :: Keyword.t()) :: String.t() | :error

  @doc """
  Executes a writing query.

  See `c:Instream.Connection.execute/2` for additional generic options.
  """
  @callback write(payload :: map | [map], opts :: Keyword.t()) :: any
end
