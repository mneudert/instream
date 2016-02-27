# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=v0.10.0)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=v0.10.0&service=github)](https://coveralls.io/github/mneudert/instream?branch=v0.10.0)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir


## Warning

__This module is experimental at the moment and may change unexpectedly.__

Tested influxdb version: `0.10.0` (see
[`.travis.yml`](https://github.com/mneudert/instream/blob/v0.10.0/.travis.yml)
to be sure)


## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [ { :instream, "~> 0.10" } ]
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
  hosts:  [ "localhost" ],
  pool:   [ max_overflow: 0, size: 1 ],
  port:   8086,
  scheme: "http",
  writer: Instream.Writer.Line
```

_Note_: While you can define as many hosts as you please only the first one
will be used. This is subject to change.

You now have a connection definition you can hook into your supervision tree:

```elixir
Supervisor.start_link(
  [ MyApp.MyConnection.child_spec ],
  strategy: :one_for_one
)
```

#### Default Connection Values

Only the `hosts` key is mandatory for a connection configuration. The following
values will be used as defaults if no other value is set:

```elixir
config :my_app, MyApp.MyConnection,
  pool:   [ max_overflow: 10, size: 5 ],
  port:   8086,
  scheme: "http",
  writer: Instream.Writer.Line
```

This also means that per default the connection uses no authentication.

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
  hosts: [ "localhost" ],
  port_udp: 8089,
  writer: Instream.Writer.UDP
```

The connection will then write using UDP and connecting to the port `:port_udp`.
All non-write queries will be send to the regular `:port` you have configured.

#### Ping

To validate a connection you can send ping requests to the server:

```elixir
Instream.Connection.ping()
```

The response will be `:pong` on success or `:error` on any failure.

### Queries

Every query can be executed asynchronously by passing `[async: true]` to
`MyApp.MyConnection.execute()`. The result will then always be an immediate
`:ok` without waiting for the query to be actually executed.

#### Administrative Queries

Managing Databases:

```elixir
# create "my_database"
"my_database"
|> Instream.Cluster.Database.create()
|> MyApp.MyConnection.execute()

# drop "my_database"
"my_database"
|> Instream.Cluster.Database.drop()
|> MyApp.MyConnection.execute()
```

Managing Retention Policies:

```elixir
# create "my_rp" retention policy
# argument order: policy, database, duration, replication, default
Instream.Cluster.RetentionPolicy.create(
  "my_rp", "my_database", "1h", 3, true
)
|> MyApp.MyConnection.execute()

# drop "my_rp" retention policy
Instream.Cluster.RetentionPolicy.drop("my_rp", "my_database")
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
- `:milli_seconds`
- `:micro_seconds`
- `:nano_seconds`

Please be aware that the UDP protocol writer does not support custom timestamp
precisions. All UDP timestamps are implicitly expected to already be at
nanosecond precision.


## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
