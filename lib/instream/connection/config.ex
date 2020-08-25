defmodule Instream.Connection.Config do
  @moduledoc """
  Configuration helper module.

  ## How To Configure

  ### Static Configuration

  One way to configure your connection is using the application environment:

      config :my_app, MyApp.MyConnection,
        database: "my_default_database",
        host: "localhost",
        port: 8086

  Please be aware that if you are using the scheme `"http+unix"` you need to
  encode the socket path yourself:

      config :my_app, MyApp.MyConnection,
        host: URI.encode_www_form("/path/to/influxdb.sock")

  ### Dynamic Configuration

  If you cannot, for whatever reason, use a static application config you
  can configure an initializer module that will be called every time your
  connection is started (or restarted) in your supervision tree:

      config :my_app, MyApp.MyConnection,
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

      defmodule MyApp.MyConnection do
        use Instream.Connection,
          otp_app: :my_app,
          config: [
            host: "localhost",
            port: 8086
          ]
      end

  These values will be overwritten by and/or merged with the application
  environment values when the configuration is accessed.

  ## Runtime and Compile Time Configuration

  The full connection configuration is split into two parts, compile time and
  runtime configuration.

  Compile time configuration values are, as the name implies, used during
  compilation for the connection module. Currently the only key in this
  category is `:loggers`.

  All other values are directly accessed from the application environment
  using `Application.get_env(connection_otp_app, connection_module)` and
  therefore can be changed without recompilation:

      old_config = MyConnection.config()
      new_config = Keyword.put(old_config, :host, "changed.host")
      :ok = Application.put_env(:my_otp_app, MyConnection, new_config)

  ## Configuration Defaults

  The following values will be used as defaults if no other value is set:

      config :my_app, MyApp.MyConnection,
        host: "localhost",
        pool: [max_overflow: 10, size: 5],
        port: 8086,
        scheme: "http",
        writer: Instream.Writer.Line,
        json_decoder: {Jason, :decode!, [[keys: :atoms]]},
        json_encoder: {Jason, :encode!, []}

  This also means that per default the connection uses no authentication.

  ## HTTP Client Configuration

  Internally all requests are done using `:hackney`.

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
  `module.decode!(binary)` and `module.encode(map)`. When using a more complete
  `{m, f}` or `{m, f, a}` configuration the data to decode/encode will passed
  as the first argument with your configured extra arguments following.

  ## Authentication

  To connect to an InfluxDB instance with http authentication enabled you
  have to configure your credentials:

      config :my_app, MyApp.MyConnection,
        auth: [method: :basic, username: "root", password: "root"]

  For `method` you can choose between header authentication (basic auth) using
  `:basic` or query parameters using `:query`. If nothing or an invalid value
  is given the connection will be made using `:basic` authentication.

  ## Writer Configuration

  If you are using the regular line protocol writer `Instream.Writer.Line`
  you are done without having anything to configure. It is used by default
  and connects to the port you have configured for connection.

  To write points over UDP you can adjust your configuration:

      config :my_app, MyApp.MyConnection,
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

      config :my_app, MyApp.MyConnection,
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
  - `response_status`: status code or `0` if not applicable/available

  When using the default logger you have to re-configure `:logger` to be
  able to get them printed:

      config :logger, :console,
        format: "\n$time $metadata[$level] $levelpad$message\n",
        metadata: [:application, :pid, :query_time, :response_status]

  To prevent a query from logging you can pass an option to the execute call:

      MyApp.MyConnection.execute(query, log: false)

      # also works with convenience methods
      MyApp.MyConnection.ping(log: false)
  """

  @compile_time_keys [:loggers]
  @global_defaults [
    host: "localhost",
    loggers: [{Instream.Log.DefaultLogger, :log, []}],
    port: 8086,
    scheme: "http",
    writer: Instream.Writer.Line
  ]

  @doc """
  Retrieves the compile time part of the connection configuration.
  """
  @spec compile_time(atom, module, Keyword.t()) :: Keyword.t()
  def compile_time(otp_app, conn, defaults \\ []) do
    @global_defaults
    |> Keyword.merge(defaults)
    |> maybe_merge_app_env(otp_app, conn)
    |> Keyword.take(@compile_time_keys)
  end

  @doc """
  Retrieves the runtime connection configuration for `conn` in `otp_app`.
  """
  @spec runtime(atom, module, nil | nonempty_list(term), Keyword.t()) :: Keyword.t()
  def runtime(otp_app, conn, keys, defaults \\ [])

  def runtime(otp_app, _, [:otp_app], _), do: otp_app

  def runtime(otp_app, conn, keys, defaults) do
    defaults
    |> maybe_merge_app_env(otp_app, conn)
    |> maybe_fetch_deep(keys)
    |> maybe_use_default(keys)
  end

  defp maybe_fetch_deep(config, nil), do: config
  defp maybe_fetch_deep(config, keys), do: get_in(config, keys)

  defp maybe_merge_app_env(config, nil, _), do: config

  defp maybe_merge_app_env(config, otp_app, conn) do
    Keyword.merge(config, Application.get_env(otp_app, conn, []))
  end

  defp maybe_use_default(config, nil), do: Keyword.merge(@global_defaults, config)
  defp maybe_use_default(nil, keys), do: get_in(@global_defaults, keys)
  defp maybe_use_default(config, _), do: config
end
