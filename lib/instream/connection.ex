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

  To get InfluxDB to verify the status of your server you can send a status call:

      MyConnection.status()

  If you are interested in the version of InfluxDB your server is
  reporting you can request it:

      MyConnection.version()

  If the version if undetectable (no header returned) it will be
  reported as `"unknown"`. If the host is unreachable or an error occurred
  the response will be `:error`.
  """

  alias Instream.Log

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
      alias Instream.Connection.Config
      alias Instream.Connection.QueryRunner
      alias Instream.Connection.Supervisor
      alias Instream.Data

      @behaviour Connection

      @otp_app opts[:otp_app]
      @config opts[:config] || []

      def child_spec(_) do
        %{
          id: __MODULE__,
          start: {Supervisor, :start_link, [__MODULE__]}
        }
      end

      def config(key \\ nil), do: Config.get(@otp_app, __MODULE__, key, @config)

      def ping(opts \\ []) do
        case config(:version) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryRunner.ping(opts, __MODULE__)
        end
      end

      def query(query, opts \\ []) do
        query
        |> Data.Read.query(opts)
        |> QueryRunner.read(opts, __MODULE__)
      end

      def status(opts \\ []) do
        case config(:version) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryRunner.status(opts, __MODULE__)
        end
      end

      def version(opts \\ []) do
        case config(:version) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryRunner.version(opts, __MODULE__)
        end
      end

      def write(payload, opts \\ []) do
        payload
        |> Data.Write.query(opts)
        |> QueryRunner.write(opts, __MODULE__)
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

  - `method`: whether to use a `:get` or `:post` request
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

  - `database`: write data to a database differing from the connection database
  - `precision`: write points with a "precision" other than `:nanosecond`

  Additional options depend on the writer module configured.
  """
  @callback write(payload :: map | [map], opts :: Keyword.t()) :: any
end
