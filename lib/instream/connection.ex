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
        password:  "pass",
        pool:      [ max_overflow: 10, size: 5 ],
        port:      8086,
        scheme:    "http",
        username:  "user"
  """

  alias Instream.Log
  alias Instream.Query
  alias Instream.Query.Builder


  @type log_entry :: Log.PingEntry.t |Log.QueryEntry.t |
                     Log.StatusEntry.t | Log.WriteEntry.t
  @type query_type :: Builder.t | Query.t | String.t


  defmacro __using__(otp_app: otp_app) do
    quote bind_quoted: [ otp_app: otp_app ] do
      alias Instream.Connection
      alias Instream.Connection.QueryPlanner
      alias Instream.Data
      alias Instream.Pool
      alias Instream.Query

      @behaviour Connection
      @otp_app   otp_app
      {:ok, config_agent} = Agent.start_link(fn -> Instream.Connection.Config.config(otp_app, __MODULE__) end)

      @config_agent config_agent

      loggers = Enum.reduce(Agent.get(@config_agent, fn(conf) -> conf[:loggers] end), quote(do: entry),
        fn (logger, acc) ->
          { mod, fun, args } = logger

          quote do
            unquote(mod).unquote(fun)(unquote(acc), unquote_splicing(args))
          end
        end)

      def __log__(entry), do: unquote(loggers)
      def __pool__,       do: __MODULE__.Pool

      def child_spec, do: Pool.Spec.spec(__MODULE__)
      def config,     do: Agent.get(@config_agent, &(&1))
      def config(conf), do: Agent.update(@config_agent, &(Keyword.merge(&1, conf)))

      # alias/convenience interface

      def ping(opts)   when is_list(opts), do: ping(nil, opts)
      def status(opts) when is_list(opts), do: status(nil, opts)


      # public interface for usage

      def execute(query, opts \\ []) do
        QueryPlanner.execute(query, opts, __MODULE__)
      end

      def ping(host \\ nil, opts \\ []) do
        %Query{ type: :ping, opts: [ host: host ] }
        |> execute(opts)
      end

      def query(query, opts \\ []), do: query |> execute(opts)

      def status(host \\ nil, opts \\ []) do
        %Query{ type: :status, opts: [ host: host ] }
        |> execute(opts)
      end

      def write(payload, opts \\ []) do
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
  Pings a server.

  By default the first server in your connection configuration will be pinged.

  The server passed does not necessarily need to belong to your connection.
  Only the connection details (scheme, port, ...) will be used to determine
  the exact url to send the ping request to.
  """
  @callback ping(host :: String.t, opts :: Keyword.t) :: :pong | :error

  @doc """
  Executes a reading query.

  See `Instream.Connection.execute/2` and `Instream.Data.Read.query/2`
  for a complete list of available options.
  """
  @callback query(query :: String.t, opts :: Keyword.t) :: any

  @doc """
  Checks the status of a connection.
  """
  @callback status(opts :: Keyword.t) :: :ok | :error

  @doc """
  Executes a writing query.

  See `Instream.Connection.execute/2` and `Instream.Data.Write.query/2`
  for a complete list of available options.
  """
  @callback write(payload :: map | [map], opts :: Keyword.t) :: any
end
