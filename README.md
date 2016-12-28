# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=master)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=master&service=github)](https://coveralls.io/github/mneudert/instream?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir


## Warning

__This module has experimental parts that may change unexpectedly.__

Tested influxdb versions:

- `1.0.0`
- `1.1.0`

(see
[`.travis.yml`](https://github.com/mneudert/instream/blob/master/.travis.yml)
to be sure)


## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [{ :instream, "~> 0.14" }]
end
```

You should also update your applications to include all necessary projects:

```elixir
def application do
  [ applications: [ :instream ]]
end
```

__Note__: If you are reading this on
[GitHub](https://github.com/mneudert/instream) then the information in this file
may be out of sync with the [Hex package](https://hex.pm/packages/instream).
If you are using this library through Hex please refer to the appropriate
documentation on HexDocs (link available on Hex).

### Testing

To run the tests you need to have the http-authentication enabled.

Using the statements from the `.travis.yml` you can generate all necessary
users for the tests with their proper privileges.


## Usage

_Note:_ Most queries require a database to operate on. The following places
will be searched (in order from top to bottom) for a configured database:

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

The `:otp_app` name and the name of the module can be freely chosen.
They only need to be linked to an entry in your `config.exs`:

```elixir
config :my_app, MyApp.MyConnection,
  database:  "my_default_database",
  host:      "localhost",
  http_opts: [ insecure: true, proxy: "http://company.proxy" ],
  pool:      [ max_overflow: 0, size: 1 ],
  port:      8086,
  scheme:    "http",
  writer:    Instream.Writer.Line
```

Configuration can be done statically (as shown above) or by referencing your
system environment:

```elixir
config :my_app, MyApp.MyConnection,
  port: { :system, "MY_ENV_VARIABLE" }
```

You now have a connection definition you can hook into your supervision tree:

```elixir
Supervisor.start_link(
  [ MyApp.MyConnection.child_spec ],
  strategy: :one_for_one
)
```

#### Runtime and Compile Time Configuration

The full connection configuration is split into two parts, compile time and
runtime configuration.

Compile time configuration are, as the name implies, used during compilation
for the connection module. Currently the only key in this category is
`:loggers`.

All other values are runtime configuration values that are directly accessed
from the application environment using
`Application.get_env(connection_otp_app, connection_module)`
and therefore can be changed without recompilation:

```elixir
old_config = MyConnection.config()
new_config = Keyword.put(old_config, :host, "changed.host")
:ok        = Application.put_env(:my_otp_app, MyConnection, new_config)
```

#### Default Connection Values

Only the `host` key is mandatory for a connection configuration. The following
values will be used as defaults if no other value is set:

```elixir
config :my_app, MyApp.MyConnection,
  pool:   [ max_overflow: 10, size: 5 ],
  port:   8086,
  scheme: "http",
  writer: Instream.Writer.Line
```

This also means that per default the connection uses no authentication.

#### HTTP Client Configuration

Internally all requests are done using
[`:hackney`](https://github.com/benoitc/hackney).

The configuration key `:http_opts` is directly passed to the client process.

Please see
[`:hackney.request/5`](https://hexdocs.pm/hackney/hackney.html#request-5)
for a complete list of available options.

#### Authentication

To connect to an influxdb instance with http_auth enabled you have to
configure your credentials:

```elixir
config :my_app, MyApp.MyConnection,
  auth: [ method: :basic, username: "root", password: "root" ]
```

For `method` you can choose between header authentication (basic auth) using
`:basic` or query parameters using `:query`. If nothing or an invalid value
is given the connection will be made using `:basic` authentication.

#### Writer Configuration

If you are using the regular line protocol writer `Instream.Writer.Line` you
are done without having anything to configure. It is used by default and
connects to the port you have configured for connection.

To write points over UDP you can adjust your configuration:

```elixir
config :my_app, MyApp.MyConnection,
  host:     "localhost",
  port_udp: 8089,
  writer:   Instream.Writer.UDP
```

The connection will then write using UDP and connecting to the port `:port_udp`.
All non-write queries will be send to the regular `:port` you have configured.

#### Logging

All queries are (by default) logged using `Logger.debug/1` via the default
logging module `Instream.Log.DefaultLogger`. To customize logging you have to
alter the configuration of your connection:

```elixir
config :my_app, MyApp.MyConnection,
  loggers: [
    { FirstLogger,  :log_fun, [] },
    { SecondLogger, :log_fun, [ :additional, :args ]}
  ]
```

This configuration replaces the default logging module.

Configuration is given as a tuple of `{ module, function, arguments }`. The log
entry will be inserted as the first argument of the method call. It will be one
of `Instream.Log.PingEntry`, `Instream.Log.QueryEntry`,
`Instream.Log.StatusEntry` or `Instream.Log.WriteEntry`, depending on what type
of request should be logged.

Please be aware that every logger has to return the entry it received in order
to allow combining multiple loggers.

In addition to query specific information every entry carries metadata around:

- `:query_time`: milliseconds it took to send request and receive the response
- `response_status`: status code or `0` if not applicable/available

When using the default logger you have to re-configure `:logger` to be able to
get them printed:

```
config :logger, :console,
  format: "\n$time $metadata[$level] $levelpad$message\n",
  metadata: [ :application, :pid, :query_time, :response_status ]
```

_Warning_: In order to log the `:pid` (provided by `:logger`) used to send the
queries you need to have at least `elixir ~> 1.1.0`. Any earlier version will
fail because the `String.Chars` protocol was not implemented for pids at that
time.

To prevent a query from logging you can pass an option to the execute call:

```elixir
query |> MyApp.MyConnection.execute(log: false)

# also works with convenience methods
MyApp.MyConnection.ping(log: false)
```

#### Ping / Status / Version

To validate a connection you can send ping requests to the server:

```elixir
MyApp.MyConnection.ping()
```

The response will be `:pong` on success or `:error` on any failure.

To ping "a host other than the first in your configuration" you can pass it
explicitly:

```elixir
MyApp.MyConnection.ping("some.host.name")
```

All values necessary to ping the host (scheme, port, ...) will be taken from
the connection used. It does not matter whether the host is configured in that
connection or not.

To get InfluxDB to verify the status of your server you can send a status call:

```elixir
MyApp.MyConnection.status()
MyApp.MyConnection.status("some.host.name")
```

If you are interested in the version of InfluxDB your server is reporting
you can request it:

```elixir
MyApp.MyConnection.version()
MyApp.MyConnection.version("some.host.name")
```

If the version if undetectable (no header returned) it will be reported
as `"unknown"`. If the host is unreachable or an error occured the response
will be `:error`.

### Queries

Every query can be executed asynchronously by passing `[async: true]` to
`MyApp.MyConnection.execute()`. The result will then always be an immediate
`:ok` without waiting for the query to be actually executed.

By default the response of a query will be a map decoded from your server's
JSON response.

Alternatively you can pass `[result_as: format]` to
`MyApp.MyConnection.execute/2` to change the result format to one of the
following:

- `:csv`  - CSV encoded response
- `:json` - JSON encoded response (implicit default)
- `:raw`  - Raw server format (JSON string)

#### Administrative Queries

Managing Databases:

```elixir
# create "my_database"
"my_database"
|> Instream.Admin.Database.create()
|> MyApp.MyConnection.execute()

# drop "my_database"
"my_database"
|> Instream.Admin.Database.drop()
|> MyApp.MyConnection.execute()
```

Managing Retention Policies:

```elixir
# create "my_rp" retention policy
# argument order: policy, database, duration, replication, default
Instream.Admin.RetentionPolicy.create(
  "my_rp", "my_database", "1h", 3, true
)
|> MyApp.MyConnection.execute()

# drop "my_rp" retention policy
Instream.Admin.RetentionPolicy.drop("my_rp", "my_database")
|> MyApp.MyConnection.execute()
```

#### Data Queries

Please see the point "Series Definitions" on how to write data
to your InfluxDB database.

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
```

#### POST Queries

Some queries require you to switch from the regular `read only context`
(all GET requets) to a `write context` (all POST requests).

When not using the query build you have to pass that information manually
to `execute/2`:

```elixir
"CREATE DATABASE create_in_write_mode"
|> MyApp.MyConnection.execute(method: :post)
```

#### Query Timeout Configuration

Using all default values and no specific parameters each query is allowed to
take up to 5000 milliseconds (`GenServer.call/2` timeout) to complete.
That may be too long or not long enough in some cases.

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

A passed or connection wide timeout configuration override any `:recv_timeout`
of your `:hackney` (HTTP client) configuration.

This does not apply to write requests. They are currently only affected by
configured `:recv_timeout` values. Setting a connection timeout enables you to
have a different timeout for read and write requests.

_Note:_ You will probably see some `MatchError` messages. These are related
to the current pool clients not matching for timeouts returned by `:hackney`.
This behaviour will change "soon-ish".


### Query Builder

__Experimental definition! Will change often and unexpected! (or may disappear...)__

Using the query builder you can avoid writing your select statements by hand:

```elixir
import Instream.Query.Builder

# SELECT one, or, more, fields FROM some_measurement
from(MySeries)
|> select([ "one", "or", "more", "fields" ])
|> MyApp.MyConnection.query()

# SELECT * FROM some_measurement WHERE binary = 'foo' AND numeric = 42
from("some_measurement")
|> where(%{ binary: "foo", numeric: 42 })
|> MyApp.MyConnection.query()
```


## Series Definitions

If you do not want to define the raw maps for writing data you can pre-define
a series for later usage:

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

These values will be pre-assigned when using the data struct.
All fields or tags without a default value will be set to `nil`.

### Writing Series Points

You can then use this module to assemble a data point (one at a time)
for writing:

```elixir
data = %MySeries{}
data = %{ data | fields: %{ data.fields | value: 17 }}
data = %{ data | tags:   %{ data.tags   | bar: "bar", foo: "foo" }}
```

And then write one or many at once:

```elixir
data
|> MyApp.MyConnection.write()

# write the point asynchronously
data
|> MyApp.MyConnection.write(async: true)

# write to a specific database
data
|> MyApp.MyConnection.write(database: "my_database")

# write multiple points at once
[ point_1, point_2, point_3 ]
|> MyApp.MyConnection.write()
```

If you want to pass an explicit timestamp to the database you can use the key
`:timestamp`:

```elixir
data = %MySeries{}
data = %{ data | timestamp: 1439587926000000000 }
```

The timestamp is (by default) expected to be a nanosecond unix timestamp.
To use different precision (for all points in this write operation!) you can
change this value by modifying your write call:

```elixir
data = %MySeries{}
data = %{ data | timestamp: 1439587926 }

data
|> MyApp.MyConnection.write([ async: true, precision: :second ])
```

Supported precision types are:

- `:hour`
- `:minute`
- `:second`
- `:millisecond`
- `:microsecond`
- `:nanosecond`

Please be aware that the UDP protocol writer does not support custom timestamp
precisions. All UDP timestamps are implicitly expected to already be at
nanosecond precision.

_Note:_ While it is possible to write multiple points a once it is currently
not supported to write them to individual databases. The first point written
defines the database, other values are silently ignored!


## Contributing

##### Custom influxdb test connection

```
export INSTREAM_HOST=localhost
export INSTREAM_HTTP_PORT=8086
```

## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
