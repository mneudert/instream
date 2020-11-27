defmodule Instream.Connection do
  @moduledoc """
  Defines a connection to an InfluxDB instance.

  ## Connection Definition

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_app
      end

  This connection will fetch it's configuration from the application environment
  as defined by `:otp_app`. As an alternative you can define the configuration
  in the module definition itself:

      defmodule MyConnection do
        use Instream.Connection,
          config: [
            version: :v1,
            host: "influxdb.example.com",
            scheme: "http"
          ]
      end

  Both inline and `:otp_app` configuration can be mixed. In this case the
  application configuration will overwrite any inline values.

  For more information on how to configure your connection please refer to
  the documentation of `Instream.Connection.Config`.

  ### InfluxDB version

  By default a connection module will expect to communicate with an
  `InfluxDB 1.x` server (`version: :v1`). Configure `version: :v2` if you
  are running an `InfluxDB 2.x` server.

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
  @type precision ::
          :hour | :minute | :second | :millisecond | :microsecond | :nanosecond | :rfc3339

  @type e_version_mismatch :: {:error, :version_mismatch}

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

      @doc false
      def __log__(entry) do
        case config([:loggers]) do
          [_ | _] = loggers ->
            Enum.reduce(loggers, entry, fn {mod, fun, extra_args}, acc ->
              apply(mod, fun, [acc | extra_args])
            end)

          _ ->
            entry
        end
      end

      def child_spec(_ \\ []) do
        %{
          id: __MODULE__.Supervisor,
          start: {Supervisor, :start_link, [__MODULE__, __MODULE__.Supervisor]}
        }
      end

      def config(keys \\ nil) do
        Connection.Config.runtime(@otp_app, __MODULE__, keys, @config)
      end

      def ping(opts \\ []) do
        case config([:version]) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryPlanner.execute(%Query{type: :ping}, opts, __MODULE__)
        end
      end

      def query(query, opts \\ []), do: QueryPlanner.execute(query, opts, __MODULE__)

      def status(opts \\ []) do
        case config([:version]) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryPlanner.execute(%Query{type: :status}, opts, __MODULE__)
        end
      end

      def version(opts \\ []) do
        case config([:version]) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryPlanner.execute(%Query{type: :version}, opts, __MODULE__)
        end
      end

      def write(payload, opts \\ []) do
        database = Data.Write.determine_database(payload, opts)
        opts = Keyword.put(opts, :database, database)

        payload
        |> Data.Write.query(opts)
        |> QueryPlanner.execute(opts, __MODULE__)
      end
    end
  end

  @doc """
  Returns a supervisable connection child_spec.
  """
  @callback child_spec(_ignored :: term) :: Supervisor.child_spec()

  @doc """
  Returns the connection configuration.
  """
  @callback config(keys :: nil | nonempty_list(term)) :: Keyword.t()

  @doc """
  Pings the connection server.
  """
  @callback ping(opts :: Keyword.t()) :: :pong | :error | e_version_mismatch

  @doc """
  Executes a reading query.

  Options:

  - `method`: whether to use a "GET" or "POST" request (as atom)
  - `precision`: return data with a "precision" other than `:rfc3339`
  """
  @callback query(query :: String.t(), opts :: Keyword.t()) :: any

  @doc """
  Checks the status of the connection server.
  """
  @callback status(opts :: Keyword.t()) :: :ok | :error | e_version_mismatch

  @doc """
  Determines the version of the connection server.
  """
  @callback version(opts :: Keyword.t()) :: String.t() | :error | e_version_mismatch

  @doc """
  Executes a writing query.

  Options:

  - `async`: pass `true` to execute the write asynchronously
  - `database`: write data to a database differing from the point database
  - `precision`: write points with a "precision" other than `:nanosecond`
  - `retention_policy`: write data to your database with a specific
    retention policy, only affects writes using the line protocol
    (`Instream.Writer.Line`, default if unconfigured)
  """
  @callback write(payload :: map | [map], opts :: Keyword.t()) :: any
end
