# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=master)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=master&service=github)](https://coveralls.io/github/mneudert/instream?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir


## Warning

__This module is highly experimental at the moment and may behave or change unexpectedly.__

Tested influxdb version: `0.9.4` (see [`.travis.yml`](.travis.yml) to be sure)


## Setup

Add Instream as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [ { :instream, "~> 0.7" } ]
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

You now have a connection definition you can hook into your supervision tree:

```elixir
Supervisor.start_link(
  [ MyApp.MyConnection.child_spec ],
  strategy: :one_for_one
)
```

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


### Queries

Every query can be executed asynchronously by passing `[async: true]` to
`MyApp.MyConnection.execute()`. The result will then always be an immediate
`:ok` without waiting for the query to be actually executed.

#### Administrative Queries

Managing Databases:

```elixir
# create "my_database"
"my_database"
|> Instream.Cluster.Database.create([ if_not_exists: true ])
|> MyApp.MyConnection.create()

# drop "my_database"
"my_database"
|> Instream.Cluster.Database.drop()
|> MyApp.MyConnection.execute()
```

Managing Retention Policies:

```elixir
# create "my_rp" retention policy
Instream.Cluster.RetentionPolicy.create(
  "my_rp", "my_database", "DURATION 1h REPLICATION 3 DEFAULT"
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
|> Instream.Data.Read.query()
|> MyApp.MyConnection.execute(database: "my_database")

# defining database in the query
"SELECT * FROM \"my_database\".\"default\".\"some_measurement\""
|> Instream.Data.Read.query()
|> MyApp.MyConnection.execute()

# passing precision (= epoch) for query results
"SELECT * FROM some_measurement"
|> Instream.Data.Read.query(precision: :minutes)
|> MyApp.MyConnection.execute()
```


## Series Definitions

If you do not want to define the raw maps for writing data you can pre-define
a seriesfor later usage:

```elixir
defmodule MySeries do
  use Instream.Series

  series do
    database    :my_database
    measurement :my_measurement

    tag :bar
    tag :foo

    field :value
  end
end
```

You can then use this module to assemble a (single!) data point for writing:

```elixir
data = %MySeries{}
data = %{ data | fields: %{ data.fields | value: 17 }}
data = %{ data | tags:   %{ data.tags   | bar: "bar", foo: "foo" }}

data
|> Instream.Data.Write.query()
|> MyApp.MyConnection.execute()

# write the point asynchronously
data
|> Instream.Data.Write.query()
|> MyApp.MyConnection.execute(async: true)
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
|> Instream.Data.Write.query(precision: :seconds)
|> MyApp.MyConnection.execute(async: true)
```

Supported precision types are:

- `:hours`
- `:minutes`
- `:seconds`
- `:milli_seconds`
- `:micro_seconds`
- `:nano_seconds`


## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
