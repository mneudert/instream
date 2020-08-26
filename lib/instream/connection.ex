defmodule Instream.Connection do
  @moduledoc """
  Defines a connection to an InfluxDB instance.

  ## Connection Definition

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_application
      end

  This connection will fetch it's configuration from the application environment
  as defined by `:otp_app`. As an alternative you can define the configuration
  in the module definition itself:

      defmodule MyConnection do
        use Instream.Connection,
          config: [
            host: "influxdb.example.com",
            scheme: "http"
          ]
      end

  Both inline and `:otp_app` configuration can be mixed. In this case the
  application configuration will overwrite any inline values.

  For more information on how to configure your connection please refer to
  the documentation of `Instream.Connection.Config`.

  ## Ping / Status / Version

  To validate a connection you can send ping requests to the server:

      MyConnection.ping()

  The response will be `:pong` on success or `:error` on any failure.

  To ping "a host other than the first in your configuration"
  you can pass it explicitly:

      MyConnection.ping("some.host.name")

  All values necessary to ping the host (scheme, port, ...) will be
  taken from the connection used. It does not matter whether the host
  is configured in that connection or not.

  To get InfluxDB to verify the status of your server you can send a status call:

      MyConnection.status()
      MyConnection.status("some.host.name")

  If you are interested in the version of InfluxDB your server is
  reporting you can request it:

      MyConnection.version()
      MyConnection.version("some.host.name")

  If the version if undetectable (no header returned) it will be
  reported as `"unknown"`. If the host is unreachable or an error occurred
  the response will be `:error`.
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
      alias Instream.Connection.Supervisor
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
        %{
          id: __MODULE__.Supervisor,
          start: {Supervisor, :start_link, [__MODULE__, __MODULE__.Supervisor]}
        }
      end

      def config(keys \\ nil) do
        Connection.Config.runtime(@otp_app, __MODULE__, keys, @config)
      end

      def execute(query, opts \\ []), do: QueryPlanner.execute(query, opts, __MODULE__)

      def ping(opts) when is_list(opts), do: ping(nil, opts)

      def ping(host \\ nil, opts \\ []),
        do: execute(%Query{type: :ping, opts: [host: host]}, opts)

      def query(query, opts \\ []), do: execute(query, opts)

      def status(opts) when is_list(opts), do: status(nil, opts)

      def status(host \\ nil, opts \\ []),
        do: execute(%Query{type: :status, opts: [host: host]}, opts)

      def version(opts) when is_list(opts), do: version(nil, opts)

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
  @callback child_spec(_ignored :: term) :: Supervisor.child_spec()

  @doc """
  Returns the connection configuration.
  """
  @callback config(keys :: nil | nonempty_list(term)) :: Keyword.t()

  @doc """
  Executes a query.
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

  Passing `[async: true]` in the options always returns :ok
  and executes the write in a background process.
  """
  @callback write(payload :: map | [map], opts :: Keyword.t()) :: any
end
