defmodule Instream.Connection do
  @moduledoc """
  Defines a connection to an InfluxDB instance.

  ## Connection Definition

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_app
      end

  This connection will fetch its configuration from the application environment
  as defined by `:otp_app`. As an alternative you can define the configuration
  in the module definition itself:

      defmodule MyConnection do
        use Instream.Connection,
          config: [
            version: :v1,
            host: "my.influxdb.host",
            scheme: "http"
          ]
      end

  Both inline and `:otp_app` configuration can be mixed. In this case the
  application configuration will overwrite any inline values.

  For more information on how to configure your connection please refer to
  the documentation of `Instream.Connection.Config`.

  ## Connection Configuration

  There are some configuration values that should be checked/changed to
  get your connection up and running:

  - `:auth`: the authentication method and credentials
  - `:host`: the hostname of the server (defaults to `"localhost"`)
  - `:port`: the port of the server (defaults to `8086`)
  - `:version`: the InfluxDB server version you are using (`:v1` or `:v2`)

  Some additional configuration options/requirements depend
  on the used version:

  - `:org`: InfluxDB v2.x organization
  - `:bucket`: InfluxDB v2.x bucket
  - `:database`: InfluxDB v1.x database

  ### InfluxDB v2.x Compatibility Endpoint (InfluxQL Queries)

  If you are using InfluxQL queries with a `:v2` connection you need to
  set the `:database` configuration to a pre-mapped database.

  Please refer to the official InfluxDB DBRP mapping documentation for details.
  """

  alias Instream.Encoder.Line
  alias Instream.Log

  @type log_entry ::
          Log.PingEntry.t()
          | Log.QueryEntry.t()
          | Log.StatusEntry.t()
          | Log.WriteEntry.t()
  @type precision ::
          :hour | :minute | :second | :millisecond | :microsecond | :nanosecond | :rfc3339

  @type e_version_mismatch :: {:error, :version_mismatch}

  @type delete_request :: %{
          required(:start) => binary,
          required(:stop) => binary,
          optional(:predicate) => binary
        }

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      alias Instream.Connection
      alias Instream.Connection.Config
      alias Instream.Connection.QueryRunnerV1
      alias Instream.Connection.QueryRunnerV2
      alias Instream.Connection.Supervisor

      @behaviour Connection

      @otp_app opts[:otp_app]
      @config opts[:config] || []

      @impl Connection
      def child_spec(_) do
        %{
          id: __MODULE__,
          start: {Supervisor, :start_link, [__MODULE__]}
        }
      end

      @impl Connection
      def config(key \\ nil), do: Config.get(@otp_app, __MODULE__, key, @config)

      @impl Connection
      def ping(opts \\ []) do
        case config(:version) do
          :v2 -> QueryRunnerV2.ping(opts, __MODULE__)
          _ -> QueryRunnerV1.ping(opts, __MODULE__)
        end
      end

      @impl Connection
      def query(query, opts \\ []) do
        case config(:version) do
          :v2 -> QueryRunnerV2.read(query, opts, __MODULE__)
          _ -> QueryRunnerV1.read(query, opts, __MODULE__)
        end
      end

      @impl Connection
      def status(opts \\ []) do
        case config(:version) do
          :v2 -> {:error, :version_mismatch}
          _ -> QueryRunnerV1.status(opts, __MODULE__)
        end
      end

      @impl Connection
      def version(opts \\ []) do
        case config(:version) do
          :v2 -> QueryRunnerV2.version(opts, __MODULE__)
          _ -> QueryRunnerV1.version(opts, __MODULE__)
        end
      end

      @impl Connection
      def write(points, opts \\ [])

      def write(point, opts) when is_map(point), do: write([point], opts)

      def write(points, opts) when is_list(points) do
        case config(:version) do
          :v2 -> QueryRunnerV2.write(points, opts, __MODULE__)
          _ -> QueryRunnerV1.write(points, opts, __MODULE__)
        end
      end

      @impl Connection
      def delete(%{start: _, stop: _} = payload, opts \\ []) do
        case config(:version) do
          :v2 ->
            Map.take(payload, [:start, :stop, :predicate])
            |> QueryRunnerV2.delete(opts, __MODULE__)

          _ ->
            {:error, :version_mismatch}
        end
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
  @callback config(key :: atom | nil) :: Keyword.t() | term

  @doc """
  Pings the connection server.
  """
  @callback ping(opts :: Keyword.t()) :: :pong | :error

  @doc """
  Executes a reading query.

  Options:

  - `database`: use a database differing from the connection config for reading
  - `method`: whether to use a `:get` or `:post` request
  - `org`: use an organization differing from the connection config for reading
  - `precision`: return data with a "precision" other than `:rfc3339`
  """
  @callback query(query :: String.t(), opts :: Keyword.t()) :: any

  @doc """
  Checks the status of the connection server.

  *Only available with InfluxDB v1.x connections.*
  """
  @callback status(opts :: Keyword.t()) :: :ok | :error | e_version_mismatch

  @doc """
  Determines the version of the connection server.

  If the version if undetectable (no header returned) it will be
  reported as `"unknown"`. If the host is unreachable or an error occurred
  the response will be `:error`.
  """
  @callback version(opts :: Keyword.t()) :: String.t() | :error

  @doc """
  Executes a writing query.

  Usable options depend on the writer module configured.
  """
  @callback write(payload :: Line.point() | [Line.point()], opts :: Keyword.t()) :: any

  @doc """
  Deletes data from an InfluxDB bucket.

  Options:

  - `bucket`: use a bucket differing from the connection config for deleting
  - `org`: use an organization differing from the connection config for deleting

  *Only available with InfluxDB v2.x connections.*
  """
  @callback delete(payload :: delete_request(), opts :: Keyword.t()) :: any
end
