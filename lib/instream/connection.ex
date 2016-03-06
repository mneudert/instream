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
        hosts:    [ "primary.example.com", "secondary.example.com" ],
        password: "pass",
        pool:     [ max_overflow: 10, size: 5 ],
        port:     8086,
        scheme:   "http",
        username: "root"
  """

  alias Instream.Query
  alias Instream.Query.Builder


  @type query_type :: Builder.t | Query.t | String.t


  defmacro __using__(otp_app: otp_app) do
    quote do
      @before_compile unquote(__MODULE__)

      alias Instream.Connection
      alias Instream.Connection.QueryPlanner
      alias Instream.Data
      alias Instream.Pool
      alias Instream.Query

      @behaviour unquote(__MODULE__)
      @otp_app   unquote(otp_app)

      def __pool__, do: __MODULE__.Pool

      def child_spec, do: Pool.Spec.spec(__MODULE__)
      def config,     do: Connection.Config.config(@otp_app, __MODULE__)

      def execute(query, opts \\ []) do
        QueryPlanner.execute(query, opts, __MODULE__)
      end

      def ping(host \\ nil) do
        %Query{ type: :ping, opts: [ host: host ] }
        |> execute()
      end

      def query(query, opts \\ []), do: query |> execute(opts)

      def status(), do: %Query{ type: :status } |> execute()

      def write(payload, opts \\ []) do
        payload
        |> Data.Write.query(opts)
        |> execute(opts)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      ## warns if deprecated JSON writer is used
      ##
      ## will be removed after influxdb has removed JSON support
      ## will only warn for all otp_apps except :instream
      config           = Application.get_env(@otp_app, __MODULE__)
      uses_json_writer = Instream.Writer.JSON == Keyword.get(config || [], :writer)
      is_not_instream  = :instream != @otp_app

      if uses_json_writer and is_not_instream do
        IO.write :stderr, """
        The connection "#{ __MODULE__ }"
        is configured to use the deprecated JSON protocol.

        The support for it will be remove with the release of InfluxDB 1.0.

        Until then it will still be available, but it is highly discouraged to
        do so. Please consider changing to the line protocol.
        """
      end
    end
  end


  @doc """
  Returns the (internal) pool module.
  """
  @callback __pool__ :: module

  @doc """
  Returns a supervisable pool child_spec.
  """
  @callback child_spec :: Supervisor.Spec.spec

  @doc """
  Returns the connection configuration.
  """
  @callback config :: Keyword.t

  @doc """
  Executes a query.

  Passing `[async: true]` in the options always returns :ok.
  The command will be executed asynchronously.
  """
  @callback execute(query :: query_type, opts  :: Keyword.t) :: any

  @doc """
  Pings a server in the connected cluster.

  By default the first server in your connection configuration will be pinged.

  The server passed does not necessarily need to be a member of your cluster.
  Only the connection details (scheme, port, ...) will be used to determine
  the exact url to send the ping request to.
  """
  @callback ping(host :: String.t) :: :pong | :error

  @doc """
  Executes a reading query.

  See `Instream.Connection.execute/2` and `Instream.Data.Read.query/2`
  for a complete list of available options.
  """
  @callback query(query :: String.t, opts :: Keyword.t) :: any

  @doc """
  Checks the status of a connection (= cluster).
  """
  @callback status() :: :ok | :error

  @doc """
  Executes a writing query.

  See `Instream.Connection.execute/2` and `Instream.Data.Write.query/2`
  for a complete list of available options.
  """
  @callback write(payload :: map | [map], opts :: Keyword.t) :: any
end
