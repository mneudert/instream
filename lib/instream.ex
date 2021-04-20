defmodule Instream do
  @moduledoc """
  InfluxDB driver for Elixir

  ## Connections

  To connect to an InfluxDB server you need a connection module:

      defmodule MyApp.MyConnection do
        use Instream.Connection, otp_app: :my_app
      end

  The `:otp_app` name and the name of the module can be freely chosen but have
  to be linked to a corresponding configuration entry. This defined connection
  module needs to be hooked up into your supervision tree:

      children = [
        # ...
        MyApp.Connection,
        # ...
      ]

  Example of the matching configuration entry:

      config :my_app, MyApp.MyConnection,
        database: "my_default_database",
        host: "localhost",
        port: 8086

  More details on connections and configuration options can be found with the
  `Instream.Connection` module.

  ## Queries

  _Note:_ Most queries require a database to operate on. The following places
  will be searched (in order from top to bottom) for a configured database:

  1. `opts[:database]` parameter
  2. `Instream.Connection` configuration
  3. No database used!

  By default the response of a query will be a map decoded from your
  server's JSON response.

  Alternatively you can pass `[result_as: format]` to
  `MyApp.MyConnection.query/2` to change the result format to
  one of the following:

  - `:csv`  CSV encoded response
  - `:json` - JSON encoded response (implicit default)
  - `:raw`  Raw server format (JSON string)

  ### Query Language Selection

  If not otherwise specified all queries will be sent as `InfluxQL`.
  This can be changed to `Flux` by passing the option `[query_language: :flux]`
  to `MyApp.MyConnection.query/2`

  ### Reading Data

      # passing database to query/2
      MyApp.MyConnection.query(
        "SELECT * FROM some_measurement",
        database: "my_database"
      )

      # defining database in the query
      MyApp.MyConnection.query(~S(
        SELECT * FROM "my_database"."default"."some_measurement"
      ))

      # passing precision (= epoch) for query results
      MyApp.MyConnection.query(
        "SELECT * FROM some_measurement",
        precision: :minutes
      )

      # using parameter binding
      MyApp.MyConnection.query(
        "SELECT * FROM some_measurement WHERE field = $field_param",
        params: %{field_param: "some_value"}
      )

  ### POST Queries

  Some queries require you to switch from the regular `read only context`
  (all GET requets) to a `write context` (all POST requests).

  When not using the query build you have to pass that information
  manually to `query/2`:

      MyApp.MyConnection.query(
        "CREATE DATABASE create_in_write_mode",
        method: :post
      )

  ### Query Timeout Configuration

  If you find your queries running into timeouts (e.g. `:hackney` not waiting
  long enough for a response) you can pass an option to the query call:

      MyApp.MyConnection.query(query, http_opts: [recv_timeout: 250])

  This value can also be set as a default using your HTTP client configuration
  (see `Instream.Connection.Config` for details). A passed configuration will
  take precedence over the connection configuration.

  ## Writing Points

  Writing data to your InfluxDB server can be done via
  `Instream.Series` modules or using raw maps.

  Please also refer to `c:Instream.Connection.write/2` for an overview
  of additional options you can use when writing data.

  ### Writing Points using Series

  Each series in your database is represented by a definition module:

      defmodule MySeries do
        use Instream.Series

        series do
          measurement "my_measurement"

          tag :bar
          tag :foo

          field :value
        end
      end

  Using this definition you can use the generated struct to create
  a data point and write it to your database:

      MyConnection.write(%MySeries{
        fields: %MySeries.Fields{value: 17},
        tags: %MySeries.Tags{bar: "bar", foo: "foo"}
      })

  More information about series definitions can be found in the
  module documentation of `Instream.Series`.

  ### Writing Points using Plain Maps

  As an alternative you can use a non-struct map to write points to a database:

      MyConnection.write([
        %{
          measurement: "my_measurement",
          fields: %{answer: 42, value: 1},
          tags: %{foo: "bar"},
          timestamp: 1_439_587_926_000_000_000
        },
        # more points possible ...
      ])

  * The field `timestamp` can be omitted, so InfluxDB will use the receive time.
  """
end
