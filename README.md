# Instream

[![Build Status](https://travis-ci.org/mneudert/instream.svg?branch=master)](https://travis-ci.org/mneudert/instream)
[![Coverage Status](https://coveralls.io/repos/mneudert/instream/badge.svg?branch=master&service=github)](https://coveralls.io/github/mneudert/instream?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/instream.svg)](https://hex.pm/packages/instream)

InfluxDB driver for Elixir

__Note__: If you are reading this on [GitHub](https://github.com/mneudert/instream) then the information in this file may be out of sync with the [Hex package](https://hex.pm/packages/instream). If you are using this library through Hex please refer to the appropriate documentation on [HexDocs](https://hexdocs.pm/instream).

## InfluxDB Support

Tested InfluxDB versions:

- `1.4.3`
- `1.5.5`
- `1.6.6`
- `1.7.10`
- `1.8.2`

(see [`.travis.yml`](https://github.com/mneudert/instream/blob/master/.travis.yml) to be sure)

## Package Setup

To use Instream with your projects, edit your `mix.exs` file and add the required dependencies:

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

### Connections

To connect to an InfluxDB server you need a connection module:

```elixir
defmodule MyConnection do
  use Instream.Connection, otp_app: :my_app
end
```

The `:otp_app` name and the name of the module can be freely chosen but have to be linked to a corresponding configuration entry. This defined connection module needs to be hooked up into your supervision tree:

```elixir
children = [
  # ...
  MyConnection,
  # ...
]
```

Example of the matching configuration entry:

```
config :my_app, MyConnection,
  database: "my_default_database",
  host: "localhost",
  port: 8086
```

More details on connections and configuration options can be found with the `Instream.Connection` module.

### Queries

```elixir
# passing database to execute/2
MyConnection.query(
  "SELECT * FROM some_measurement",
  database: "my_database"
)

# defining database in the query
MyConnection.query(
  "SELECT * FROM \"my_database\".\"default\".\"some_measurement\""
)

# passing precision (= epoch) for query results
MyConnection.query(
  "SELECT * FROM some_measurement",
  precision: :minutes
)

# using parameter binding
MyConnection.query(
  "SELECT * FROM some_measurement WHERE field = $field_param",
  params: %{field_param: "some_value"}
)
```

A more detailed documentation on queries (reading/writing/options) is available in the main `Instream` module documentation.

## Series Definitions

If you do not want to define the raw maps for writing data you can pre-define a series for later usage:

```elixir
defmodule MySeries do
  use Instream.Series

  series do
    database "my_database"
    measurement "my_measurement"

    tag :bar
    tag :foo

    field :value
  end
end
```

More information about series definitions can be found in the module documentation of `Instream.Series`.

### Writing Series Points

You can then use this module to assemble a data point (one at a time) for writing:

```elixir
data = %MySeries{}
data = %{data | fields: %{data.fields | value: 17}}
data = %{data | tags: %{data.tags | bar: "bar", foo: "foo"}}
```

And then write one or many at once:

```elixir
MyConnection.write(data)

# write the point asynchronously
MyConnection.write(data, async: true)

# write to a specific database
MyConnection.write(data, database: "my_database")

# write multiple points at once
MyConnection.write([point_1, point_2, point_3])
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

MyConnection.write(data, async: true, precision: :second)
```

If you want to specify the target retention policy name for the write, you can do so like this (line protocol only!):

```elixir
MyConnection.write(data, retention_policy: "two_weeks")
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

## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
