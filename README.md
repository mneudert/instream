# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=master)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=master&service=github)](https://coveralls.io/github/mneudert/instream?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir


## Warning

__This module has experimental parts that may change unexpectedly.__

Tested influxdb version: `0.13.0` (see
[`.travis.yml`](https://github.com/mneudert/instream/blob/master/.travis.yml)
to be sure)


## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [ { :instream, "~> 0.12" } ]
end
```

You should also update your applications to include all necessary projects:

```elixir
def application do
  [ applications: [ :instream ] ]
end
```

### Testing

To run the tests you need to have the http-authentication enabled.

Using the statements from the `.travis.yml` you can generate all necessary
users for the tests with their proper privileges.


## Usage

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
  host:      "localhost",
  http_opts: [ insecure: true, proxy: "http://company.proxy" ],
  pool:      [ max_overflow: 0, size: 1 ],
  port:      8086,
  scheme:    "http",
  writer:    Instream.Writer.Line
```

You now have a connection definition you can hook into your supervision tree:

```elixir
Supervisor.start_link(
  [ MyApp.MyConnection.child_spec ],
  strategy: :one_for_one
)
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
    { SecondLogger, :log_fun, [ :additional, :args ] }
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
  metadata: [:application, :pid, :query_time, :response_status]
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

#### Ping / Status

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

To get InfluxDB to verify status of your server you can send a status call:

```elixir
MyApp.MyConnection.status()
```

As with ping requests you can target a specific host:

```elixir
MyApp.MyConnection.status("some.host.name")
```

### Queries

Every query can be executed asynchronously by passing `[async: true]` to
`MyApp.MyConnection.execute()`. The result will then always be an immediate
`:ok` without waiting for the query to be actually executed.

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

You can include a default value for tags in your series definition:

```elixir
series do
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

The timestamp is (by default) expected to be a nanosecond unix timestamp. To use
a different precision (for all points in this write operation!) you can change
this value by modifying your write call:

```elixir
data = %MySeries{}
data = %{ data | timestamp: 1439587926 }

data
|> MyApp.MyConnection.write([ async: true, precision: :seconds ])
```

Supported precision types are:

- `:hours`
- `:minutes`
- `:seconds`
- `:milliseconds`
- `:microseconds`
- `:nanoseconds`

Please be aware that the UDP protocol writer does not support custom timestamp
precisions. All UDP timestamps are implicitly expected to already be at
nanosecond precision.


## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
