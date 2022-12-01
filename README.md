# Instream

InfluxDB driver for Elixir

## InfluxDB Support

Tested InfluxDB versions:

- `1.7.11`
- `1.8.10`
- `2.0.9`
- `2.1.1`
- `2.2.0`
- `2.3.0`
- `2.4.0`
- `2.5.1`

## Package Setup

To use Instream with your projects, edit your `mix.exs` file and add the required dependencies:

```elixir
defp deps do
  [
    # ...
    {:instream, "~> 2.0"},
    # ...
  ]
end
```

### Testing

To run the tests you need to have HTTP authentication enabled.

The following environment variables are used to select some test suites and the InfluxDB version under test:

- `INFLUXDB_HOST`: the hostname where the InfluxDB can be reached (e.g. `localhost`)
- `INFLUXDB_PORT`: the port where InfluxDB receives queries on (e.g. `8086`)
- `INFLUXDB_VERSION`: the tested InfluxDB version as `major.minor`, e.g. `"1.8"`, `"2.0"`, or `"2.4"`
- `INFLUXDB_V1_DATABASE`: the database used for InfluxDB v1.x tests _(will receive a `DROP` and `CREATE` during test start!)_
- `INFLUXDB_V1_PORT_UDP`: the UDP port used for writer testing _(InfluxDB 1.x only, should be configured to write to INFLUXDB\_V1\_DATABASE)_
- `INFLUXDB_V1_SOCKET`: path to the InfluxDB unix socket _(InfluxDB 1.8 only)_
- `INFLUXDB_V2_TOKEN`: the authentication token used _(InfluxDB 2.x only)_

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
# InfluxDB v2.x
config :my_app, MyConnection,
  auth: [method: :token, token: "my_token"],
  bucket: "my_default_bucket",
  org: "my_default_org",
  host: "my.influxdb.host",
  version: :v2

# InfluxDB v1.x
config :my_app, MyConnection,
  auth: [username: "my_username", password: "my_password"],
  database: "my_default_database",
  host: "my.influxdb.host"
```

More details on connections and configuration options can be found with the `Instream.Connection` and `Instream.Connection.Config` modules.

### Queries

```elixir
# Flux query
MyConnection.query(
  """
    from(bucket: "#{MyConnection.config(:bucket)}")
    |> range(start: -5m)
    |> filter(fn: (r) =>
      r._measurement == "instream_examples"
    )
    |> first()
  """
)

# InfluxQL query
MyConnection.query("SELECT * FROM instream_examples")
```

A more detailed documentation on queries (reading/writing/options) is available in the documentation for the modules `Instream` and `Instream.Connection`.

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
