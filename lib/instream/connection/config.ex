defmodule Instream.Connection.Config do
  @moduledoc """
  Configuration helper module.

  ## How To Configure

  ### Static Configuration

  One way to configure your connection is using the application environment:

      config :my_app, MyConnection,
        database: "my_default_database",
        host: "localhost",
        port: 8086

  Please be aware that if you are using the scheme `"http+unix"` you need to
  encode the socket path yourself:

      config :my_app, MyConnection,
        host: URI.encode_www_form("/path/to/influxdb.sock")

  ### Dynamic Configuration

  If you cannot, for whatever reason, use a static application config you
  can configure an initializer module that will be called every time your
  connection is started (or restarted) in your supervision tree:

      config :my_app, MyConnection,
        init: {MyInitModule, :my_init_fun}

      defmodule MyInitModule do
        @spec my_init_fun(module) :: :ok
        def my_init_fun(conn) do
          config =
            Keyword.merge(
              conn.config(),
              host: "localhost",
              port: 64210
            )

          Application.put_env(:my_app, conn, config)
        end
      end

  When the connection is started the function will be called with the
  connection module as the first (and only) parameter. This will be done
  before the connection is available for use.

  The function is expected to always return `:ok`.

  ### Inline Configuration

  For some use cases (e.g. testing) it may be sufficient to define hardcoded
  configuration defaults outside of your application environment:

      defmodule MyConnection do
        use Instream.Connection,
          otp_app: :my_app,
          config: [
            host: "localhost",
            port: 8086
          ]
      end

  These values will be overwritten by and/or merged with the application
  environment values when the configuration is accessed.

  ## Configuration Defaults

  The following values will be used as defaults if no other value is set:

      config :my_app, MyConnection,
        version: :v1,
        host: "localhost",
        port: 8086,
        scheme: "http",
        http_client: Instream.HTTPClient.Hackney,
        writer: Instream.Writer.Line,
        json_decoder: {Jason, :decode!, [[keys: :atoms]]},
        json_encoder: {Jason, :encode!, []}

  This also means that per default the connection uses no authentication.

  ## InfluxDB Version Configuration

  By default (`version: :v1`) the communication will be done with the
  expectation of an `InfluxDB 1.x` server responding. If you are communicating
  with an `InfluxDB 2.x` server please configure `version: :v2`.

  Any methods not supported by your configured version will respond with a
  special error tuple `{:error, :version_mismatch}` when called.

  ## HTTP Client Configuration

  Internally all requests are done using the configured `:http_client`.

  ### Instream.HTTPClient.Hackney

  Default for no otherwise configured HTTP Client is `:hackney`.

  The configuration key `:http_opts` is directly passed to the client process.
  Parts of it are also used internally by `:hackney` to control more generic
  behaviour (request pool to be used and it's configuration).

  Please see `:hackney.request/5` for a complete list of available options.

  Setting the `:http_opts` key when calling a connection method allows usage
  of per-call options. The options are merged with the connection options and
  then passed on.

  ## JSON Configuration

  By default the library used for encoding/decoding JSON is `:jason`.
  For the time `:instream` directly depends on it to ensure it is available.

  If you want to use another library you can switch it:

      config :my_app, MyConnection,
        json_decoder: MyJSONLibrary,
        json_encoder: MyJSONLibrary

      config :my_app, MyConnection,
        json_decoder: {MyJSONLibrary, :decode_argless},
        json_encoder: {MyJSONLibrary, :decode_argless}

      config :my_app, MyConnection,
        json_decoder: {MyJSONLibrary, :decode_it, [[keys: :atoms]]},
        json_encoder: {MyJSONLibrary, :decode_it, []}

  If you configure only a module name it will be called as
  `module.decode!(binary)` and `module.encode!(map)`. When using a more complete
  `{m, f}` or `{m, f, a}` configuration the data to decode/encode will passed
  as the first argument with your configured extra arguments following.

  ## Authentication

  To connect to an InfluxDB instance with http authentication enabled you
  have to configure your credentials:

      config :my_app, MyConnection,
        auth: [method: :basic, username: "root", password: "root"]

      config :my_app, MyConnection,
        auth: [method: :token, token: "Ln0quM0YVQcJilrp"]

  For `method` you can choose between header authentication using
  `:basic` (InfluxDB v1) or `:token` (InfluxDB v2), or query parameters using
  `:query`. If nothing or an invalid value is given the connection will be made
  using `:basic` authentication.

  ## Writer Configuration

  If you are using the regular line protocol writer `Instream.Writer.Line`
  you are done without having anything to configure. It is used by default
  and connects to the port you have configured for connection.

  To write points over UDP you can adjust your configuration:

      config :my_app, MyConnection,
        host: "localhost",
        port_udp: 8089,
        writer: Instream.Writer.UDP

  The connection will then write using UDP and connecting to the port
  `:port_udp`. All non-write queries will be send to the regular `:port`
  you have configured.

  ## Logging

  All queries are (by default) logged using `Logger.debug/1` via the default
  logging module `Instream.Log.DefaultLogger`. To customize logging you have
  to alter the configuration of your connection:

      config :my_app, MyConnection,
        loggers: [
          {FirstLogger, :log_fun, []},
          {SecondLogger, :log_fun, [:additional, :args]}
        ]

  This configuration replaces the default logging module.

  Configuration is given as a tuple of `{module, function, arguments}`.
  The log entry will be inserted as the first argument of the method call.
  It will be  one of `Instream.Log.PingEntry`, `Instream.Log.QueryEntry`,
  `Instream.Log.StatusEntry` or `Instream.Log.WriteEntry`, depending on
  what type of request should be logged.

  Please be aware that every logger has to return the entry it received in
  order to allow combining multiple loggers.

  In addition to query specific information every entry carries metadata around:

  - `:query_time`: milliseconds it took to send request and receive the response
  - `:response_status`: status code or `0` if not applicable/available

  When using the default logger you have to re-configure `:logger` to be
  able to get them printed:

      config :logger, :console,
        format: "\n$time $metadata[$level] $levelpad$message\n",
        metadata: [:application, :pid, :query_time, :response_status]

  To prevent a query from logging you can pass an option:

      MyConnection.ping(log: false)
      MyConnection.query(query, log: false)
  """

  @global_defaults [
    host: "localhost",
    loggers: [{Instream.Log.DefaultLogger, :log, []}],
    port: 8086,
    scheme: "http",
    version: :v1,
    http_client: Instream.HTTPClient.Hackney,
    writer: Instream.Writer.Line
  ]

  @doc """
  Retrieves the connection configuration for `conn` in `otp_app`.
  """
  @spec get(atom, module, nil | atom, Keyword.t()) :: Keyword.t()
  def get(otp_app, _, :otp_app, _), do: otp_app
  def get(nil, _, nil, defaults), do: Keyword.merge(@global_defaults, defaults)

  def get(nil, _, key, defaults) do
    @global_defaults
    |> Keyword.merge(defaults)
    |> Keyword.get(key)
  end

  def get(otp_app, conn, key, defaults) do
    app_env = Application.get_env(otp_app, conn, [])

    config =
      @global_defaults
      |> Keyword.merge(defaults)
      |> Keyword.merge(app_env)

    case key do
      nil -> config
      _ -> Keyword.get(config, key)
    end
  end
end
