# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=v0.22.0)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=v0.22.0&service=github)](https://coveralls.io/github/mneudert/instream?branch=v0.22.0)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir

__Note__: If you are reading this on [GitHub](https://github.com/mneudert/instream) then the information in this file may be out of sync with the [Hex package](https://hex.pm/packages/instream). If you are using this library through Hex please refer to the appropriate documentation on [HexDocs](https://hexdocs.pm/instream).

## InfluxDB Support

Tested InfluxDB versions:

- `1.4.3`
- `1.5.5`
- `1.6.6`
- `1.7.6`

(see [`.travis.yml`](https://github.com/mneudert/instream/blob/v0.22.0/.travis.yml) to be sure)

## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [
    # ...
    {:instream, "~> 0.22"},
    # ...
  ]
end
```

### Testing

To run the tests you need to have the http-authentication enabled.

Using the statements from the `.travis.yml` you can generate all necessary users for the tests with their proper privileges.

The test suite will automatically exclude tests not working for your current environment. This includes checking the available InfluxDB version and OTP release.

If you have not configured your InfluxDB testing instance to provide an UDP endpoint to the "test\_database", you can exclude these tests manually:

```shell
mix test --exclude udp
```

## Usage

_Note:_ Most queries require a database to operate on. The following places will be searched (in order from top to bottom) for a configured database:

1. `opts[:database]` parameter
2. Series struct (if used)
3. Connection configuration
4. No database used!

### Connections

Defining a connection requires defining a module:

```elixir
defmodule MyApp.MyConnection do
  use Instream.Connection, otp_app: :my_app
end
```

The `:otp_app` name and the name of the module can be freely chosen but have to be linked to a corresponding configuration entry. This defined connection module needs to be hooked up into your supervision tree:

```elixir
children = [
  # ...
  MyApp.Connection,
  # ...
]
```

#### Configuration (static)

The most simple way is to use a completely static configuration:

```elixir
config :my_app, MyApp.MyConnection,
  database:  "my_default_database",
  host: "localhost",
  http_opts: [insecure: true, proxy: "http://company.proxy"],
  pool: [max_overflow: 10, size: 50],
  port: 8086,
  scheme: "http",
  writer: Instream.Writer.Line
```

Please be aware that if you are using the scheme `"http+unix"` you need to encode the socket path yourself:

```
config :my_app, MyApp.MyConnection,
  host: URI.encode_www_form("/path/to/influxdb.sock")
```

#### Configuration (dynamic)

If you cannot, for whatever reason, use a static application config you can configure an initializer module that will be called every time your connection is started (or restarted) in your supervision tree:

```elixir
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
```

When the connection is started the function will be called with the connection module as the first (and only) parameter. This will be done before the connection is available for use.

The function is expected to always return `:ok`.

#### Configuration (inline defaults)

For some use cases (e.g. testing) it may be sufficient to define hardcoded configuration defaults outside of your application environment:

```elixir
defmodule MyApp.MyConnection do
  use Instream.Connection,
    otp_app: :my_app,
    config: [
      host: "localhost",
      port: 8086
    ]
end
```

These values will be overwritten by and/or merged with the application environment values when the configuration is accessed.

#### Runtime and Compile Time Configuration

The full connection configuration is split into two parts, compile time and runtime configuration.

Compile time configuration are, as the name implies, used during compilation for the connection module. Currently the only key in this category is `:loggers`.

All other values are runtime configuration values that are directly accessed from the application environment using `Application.get_env(connection_otp_app, connection_module)` and therefore can be changed without recompilation:

```elixir
old_config = MyConnection.config()
new_config = Keyword.put(old_config, :host, "changed.host")
:ok = Application.put_env(:my_otp_app, MyConnection, new_config)
```

#### Default Connection Values

The following values will be used as defaults if no other value is set:

```elixir
config :my_app, MyApp.MyConnection,
  host: "localhost",
  pool: [max_overflow: 10, size: 5],
  port: 8086,
  scheme: "http",
  writer: Instream.Writer.Line,
  json_decoder: Poison,
  json_encoder: Poison
```

This also means that per default the connection uses no authentication.

#### HTTP Client Configuration

Internally all requests are done using [`:hackney`](https://github.com/benoitc/hackney).

The configuration key `:http_opts` is directly passed to the client process. Parts of it are also used internally by `:hackney` to control more generic behaviour (request pool to be used and it's configuration).

Please see [`:hackney.request/5`](https://hexdocs.pm/hackney/hackney.html#request-5) for a complete list of available options.

Setting the `:http_opts` key when calling a connection method allows usage of per-call options. The options are merged with the connection options and then passed on.

#### JSON Configuration

By default the library used for encoding/decoding JSON is `:poison`. For the time `:instream` directly depends on it to ensure it is available.

If you want to use another library you can switch it:

```elixir
config :my_app, MyConnection,
  json_decoder: MyJSONLibrary,
  json_encoder: MyJSONLibrary

config :my_app, MyConnection,
  json_decoder: {MyJSONLibrary, :decode_argless},
  json_encoder: {MyJSONLibrary, :decode_argless}

config :my_app, MyConnection,
  json_decoder: {MyJSONLibrary, :decode_it, [[keys: :atoms]]},
  json_encoder: {MyJSONLibrary, :decode_it, []}
```

If you configure only a module name it will be called as `module.decode!(binary)` and `module.encode(map)`. When using a more complete `{m, f}` or `{m, f, a}` configuration the data to decode/encode will passed as the first argument with your configured extra arguments following.

#### Authentication

To connect to an InfluxDB instance with http authentication enabled you have to configure your credentials:

```elixir
config :my_app, MyApp.MyConnection,
  auth: [method: :basic, username: "root", password: "root"]
```

For `method` you can choose between header authentication (basic auth) using `:basic` or query parameters using `:query`. If nothing or an invalid value is given the connection will be made using `:basic` authentication.

#### Writer Configuration

If you are using the regular line protocol writer `Instream.Writer.Line` you are done without having anything to configure. It is used by default and connects to the port you have configured for connection.

To write points over UDP you can adjust your configuration:

```elixir
config :my_app, MyApp.MyConnection,
  host: "localhost",
  port_udp: 8089,
  writer: Instream.Writer.UDP
```

The connection will then write using UDP and connecting to the port `:port_udp`. All non-write queries will be send to the regular `:port` you have configured.

#### Logging

All queries are (by default) logged using `Logger.debug/1` via the default logging module `Instream.Log.DefaultLogger`. To customize logging you have to alter the configuration of your connection:

```elixir
config :my_app, MyApp.MyConnection,
  loggers: [
    {FirstLogger, :log_fun, []},
    {SecondLogger, :log_fun, [:additional, :args]}
  ]
```

This configuration replaces the default logging module.

Configuration is given as a tuple of `{module, function, arguments}`. The log entry will be inserted as the first argument of the method call. It will be one of `Instream.Log.PingEntry`, `Instream.Log.QueryEntry`, `Instream.Log.StatusEntry` or `Instream.Log.WriteEntry`, depending on what type of request should be logged.

Please be aware that every logger has to return the entry it received in order to allow combining multiple loggers.

In addition to query specific information every entry carries metadata around:

- `:query_time`: milliseconds it took to send request and receive the response
- `response_status`: status code or `0` if not applicable/available

When using the default logger you have to re-configure `:logger` to be able to get them printed:

```
config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [:application, :pid, :query_time, :response_status]
```

To prevent a query from logging you can pass an option to the execute call:

```elixir
MyApp.MyConnection.execute(query, log: false)

# also works with convenience methods
MyApp.MyConnection.ping(log: false)
```

#### Ping / Status / Version

To validate a connection you can send ping requests to the server:

```elixir
MyApp.MyConnection.ping()
```

The response will be `:pong` on success or `:error` on any failure.

To ping "a host other than the first in your configuration" you can pass it explicitly:

```elixir
MyApp.MyConnection.ping("some.host.name")
```

All values necessary to ping the host (scheme, port, ...) will be taken from the connection used. It does not matter whether the host is configured in that connection or not.

To get InfluxDB to verify the status of your server you can send a status call:

```elixir
MyApp.MyConnection.status()
MyApp.MyConnection.status("some.host.name")
```

If you are interested in the version of InfluxDB your server is reporting you can request it:

```elixir
MyApp.MyConnection.version()
MyApp.MyConnection.version("some.host.name")
```

If the version if undetectable (no header returned) it will be reported as `"unknown"`. If the host is unreachable or an error occurred the response will be `:error`.

### Queries

Every query can be executed asynchronously by passing `[async: true]` to `MyApp.MyConnection.execute()`. The result will then always be an immediate `:ok` without waiting for the query to be actually executed.

By default the response of a query will be a map decoded from your server's JSON response.

Alternatively you can pass `[result_as: format]` to `MyApp.MyConnection.execute/2` to change the result format to one of the following:

- `:csv`  - CSV encoded response
- `:json` - JSON encoded response (implicit default)
- `:raw`  - Raw server format (JSON string)

#### Query Language Selection

If not otherwise specified all queries will be sent as `InfluxQL`. This can be changed to `Flux` by passing the option `[query_language: :flux]` to `MyApp.MyConnection.execute/2`

#### Data Queries

Please see the point "Series Definitions" on how to write data to your InfluxDB database.

Reading data:

```elixir
# passing database to execute/1
"SELECT * FROM some_measurement"
|> MyApp.MyConnection.query(database: "my_database")

# defining database in the query
"SELECT * FROM \"my_database\".\"default\".\"some_measurement\""
|> MyApp.MyConnection.query()

# passing precision (= epoch) for query results
"SELECT * FROM some_measurement"
|> MyApp.MyConnection.query(precision: :minutes)

# using parameter binding
"SELECT * FROM some_measurement WHERE field = $field_param"
|> MyApp.MyConnection.query(params: %{field_param: "some_value"})
```

#### POST Queries

Some queries require you to switch from the regular `read only context` (all GET requets) to a `write context` (all POST requests).

When not using the query build you have to pass that information manually to `execute/2`:

```elixir
"CREATE DATABASE create_in_write_mode"
|> MyApp.MyConnection.execute(method: :post)
```

#### Query Timeout Configuration

Using all default values and no specific parameters each query is allowed to take up to 5000 milliseconds (`GenServer.call/2` timeout) to complete. That may be too long or not long enough in some cases.

To change that timeout you can configure your connection:

```elixir
# lowering timeout to 500 ms
config :my_app,
  MyApp.MyConnection,
    query_timeout: 500
```

or pass an individual timeout for a single query:

```elixir
MyApp.MyConnection.execute(query, timeout: 250)
```

A passed or connection wide timeout configuration override any `:recv_timeout` of your `:hackney` (HTTP client) configuration.

This does not apply to write requests. They are currently only affected by configured `:recv_timeout` values. Setting a connection timeout enables you to have a different timeout for read and write requests.

For the underlying worker pool you can define a separate timeout:

```elixir
config :my_app,
  MyApp.MyConnection,
    pool_timeout: 500
```

This configuration will be used to wait for an available worker to execute a query and defaults to `5_000`.

## Series Definitions

If you do not want to define the raw maps for writing data you can pre-define a series for later usage:

```elixir
defmodule MySeries do
  use Instream.Series

  series do
    database    "my_database"
    measurement "my_measurement"

    tag :bar
    tag :foo

    field :value
  end
end
```

### Default Values

You can include a default value for tags and fields in your series definition:

```elixir
series do
  measurement "my_measurement"

  tag :host, default: "www"

  field :value, default: 100
end
```

These values will be pre-assigned when using the data struct. All fields or tags without a default value will be set to `nil`.

### Series Hydration (Experimental)

Whenever you want to convert a plain map or a query result into a specific series you can use the builtin hydration methods:

```elixir
# plain map
MySeries.from_map(%{
  timestamp: 1234567890,
  some_tag: "hydrate",
  some_field: 123
})

# query result
"SELECT * FROM \"my_measurement\""
|> MyConnection.query()
|> MySeries.from_result()
```

The timestamp itself is kept "as is". There is (at the moment) no automatic conversion done between to ensure a consistent precisions. This should be done beforehand or kept in mind when writing a hydrated point.

### Writing Series Points

You can then use this module to assemble a data point (one at a time) for writing:

```elixir
data = %MySeries{}
data = %{data | fields: %{data.fields | value: 17}}
data = %{data | tags: %{data.tags | bar: "bar", foo: "foo"}}
```

And then write one or many at once:

```elixir
MyApp.MyConnection.write(data)

# write the point asynchronously
MyApp.MyConnection.write(data, async: true)

# write to a specific database
MyApp.MyConnection.write(data, database: "my_database")

# write multiple points at once
MyApp.MyConnection.write([point_1, point_2, point_3])
```

If you want to pass an explicit timestamp to the database you can use the key `:timestamp`:

```elixir
data = %MySeries{}
data = %{data | timestamp: 1439587926000000000}
```

The timestamp is (by default) expected to be a nanosecond unix timestamp. To use different precision (for all points in this write operation!) you can change this value by modifying your write call:

```elixir
data = %MySeries{}
data = %{data | timestamp: 1439587926}

MyApp.MyConnection.write(data, async: true, precision: :second)
```

If you want to specify the target retention policy name for the write, you can do so like this (line protocol only!):

```elixir
MyApp.MyConnection.write(data, retention_policy: "two_weeks")
```

Supported precision types are:

- `:hour`
- `:minute`
- `:second`
- `:millisecond`
- `:microsecond`
- `:nanosecond`

Please be aware that the UDP protocol writer does not support custom timestamp precisions. All UDP timestamps are implicitly expected to already be at nanosecond precision.

_Note:_ While it is possible to write multiple points a once it is currently not supported to write them to individual databases. The first point written defines the database, other values are silently ignored!

### Writing Raw Points

When not using Series Definitions raw points can be written using a map like this:

```elixir
%{
  points: [
    %{
      database: "my_database", # Can be omitted, so default is used.
      measurement: "my_measurement",
      fields: %{answer: 42, value: 1},
      tags: %{foo: "bar"},
      timestamp: 1439587926000000000 # Nanosecond unix timestamp with default precision, can be omitted.
    },
    # more points possible ...
  ],
  database: "my_database", # Can be omitted, so default is used.
}
|> MyApp.MyConnection.write()
```

* The field `timestamp` can be omitted, so InfluxDB will use the receive time.
* The field `database` can be used to write to a custom database. 

Please be aware that only the database from the first point will be used when writing multiple points.

## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
