# Instream

InfluxDB driver for Elixir

## InfluxDB Support

Tested InfluxDB versions:

- `1.7.11`
- `1.8.6`
- `2.0.7`

## Package Setup

To use Instream with your projects, edit your `mix.exs` file and add the required dependencies:

```elixir
defp deps do
  [
    # ...
    {:instream, "~> 1.0"},
    # ...
  ]
end
```

### Testing

To run the tests you need to have HTTP authentication enabled.

The test suite will automatically try to exclude tests not expected to work for your InfluxDB version.

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
# passing database to query/2
MyConnection.query(
  "SELECT * FROM some_measurement",
  database: "my_database"
)

# defining database in the query
MyConnection.query(~S(
  SELECT * FROM "my_database"."default"."some_measurement"
))

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
MyConnection.write(point)
MyConnection.write([point_1, point_2, point_3])
```

## License

[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
