defmodule Instream do
  @moduledoc """
  InfluxDB driver for Elixir

  ## Connections

  To connect to an InfluxDB server you need a connection module:

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_app
      end

  The `:otp_app` name and the name of the module can be freely chosen but have
  to be linked to a corresponding configuration entry. This defined connection
  module needs to be hooked up into your supervision tree:

      children = [
        # ...
        MyConnection,
        # ...
      ]

  Example of the matching configuration entry:

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

  More details on connections and configuration options can be found with the
  modules `Instream.Connection` and `Instream.Connection.Config`.

  ## Queries

  To read data from your InfluxDB server you should send a query:

      # Flux query
      MyConnection.query(~s(
        from(bucket: "\#{MyConnection.config(:bucket)}")
        |> range(start: -5m)
        |> filter(fn: (r) =>
          r._measurement == "instream_examples"
        )
        |> first()
      ))

      # InfluxQL query
      MyConnection.query("SELECT * FROM instream_examples")

  Most of the queries you send require a `:database` or
  `:bucket`/`:organization` to operate on.

  These values will be taken from your connection configuration by default.
  By using the option argument of `MyConnection.query/2` you can pass different
  values to use on a per-query basis:

      MyConnection.query("... query ...", database: "my_other_database")

      MyConnection.query(
        "... query ...",
        bucket: "my_other_bucket",
        org: "my_other_organization"
      )

  Responses from a query will be decoded into maps by default.

  Depending on your InfluxDB version you can use the `:result_as` option
  argument to skip the decoding or request a non-default response type:

  - `result_as: :csv`: response as CSV when using InfluxDB v1
  - `result_as: :raw`: result as sent from the server without decoding

  ### Query Language Selection

  Depending on your configured InfluxDB version all queries will be treated
  as `:flux` (v2) or `:influxql` by default. You can send a query in the
  non-default language by passing the `:query_language` option:

      MyConnection.query("... query ...", query_language: :flux)
      MyConnection.query("... query ...", query_language: :influxql)

  ### Query Parameter Binding (InfluxDB v1.x)

  Queries can be parameterized, for example when you are dealing with
  untrusted user input:

      MyConnection.query(
        "SELECT * FROM some_measurement WHERE field = $field_param",
        params: %{field_param: "some_value"}
      )

  ### POST Queries (InfluxDB v1.x)

  Some queries require you to switch from the regular `read only context`
  (all GET requests) to a `write context` (all POST requests).

  When not using the query build you have to pass that information
  manually to `query/2`:

      MyConnection.query(
        "CREATE DATABASE create_in_write_mode",
        method: :post
      )

  ### Query Timeout Configuration

  If you find your queries running into timeouts (e.g. `:hackney` not waiting
  long enough for a response) you can pass an option to the query call:

      MyConnection.query(query, http_opts: [recv_timeout: 250])

  This value can also be set as a default using your
  [HTTP client configuration](`Instream.Connection.Config`).
  A passed configuration will take precedence over the connection configuration.

  ## Writing Points

  Writing data to your InfluxDB server is done using either `Instream.Series`
  modules or raw maps.

  Depending on your [connection configuration](`Instream.Connection.Config`)
  the selected writer module provides additional options.

  The write function can be used with a single or multiple data points:

      MyConnection.write(point)
      MyConnection.write([point_1, point_2])

  ### Writing Points using Series

  Each series in your database can be represented using a definition module:

      defmodule MySeries do
        use Instream.Series

        series do
          measurement "my_measurement"

          tag :bar
          tag :foo

          field :value
        end
      end

  This module will provide you with a struct you can use to define points
  you want to write to your database:

      MyConnection.write(%MySeries{
        fields: %MySeries.Fields{value: 17},
        tags: %MySeries.Tags{bar: "bar", foo: "foo"}
      })

  More information about series definitions can be found in the
  module documentation of `Instream.Series`.

  ### Writing Points using Plain Maps

  As an alternative you can use a non-struct map to write points to a database:

      MyConnection.write(
        %{
          measurement: "my_measurement",
          fields: %{answer: 42, value: 1},
          tags: %{foo: "bar"},
          timestamp: 1_439_587_926_000_000_000
        },
        # more points possible ...
      )

  The field `:timestamp` is optional. InfluxDB will use the receive time of
  the write request if it is missing.
  """
end
