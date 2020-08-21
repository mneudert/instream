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
        database:  "my_default_database",
        host: "localhost",
        port: 8086

  More details on connections and configuration options can be found with the
  `Instream.Connection` module.

  ## Queries

  _Note:_ Most queries require a database to operate on. The following places
  will be searched (in order from top to bottom) for a configured database:

  1. `opts[:database]` parameter
  2. `Instream.Series` struct (if used)
  3. `Instream.Connection` configuration
  4. No database used!

  Write queries can be executed asynchronously by passing `[async: true]` to
  `MyApp.MyConnection.execute()`. The result will then always be an immediate
  `:ok` without waiting for the query to be actually executed.

  By default the response of a query will be a map decoded from your
  server's JSON response.

  Alternatively you can pass `[result_as: format]` to
  `MyApp.MyConnection.execute/2` to change the result format to
  one of the following:

  - `:csv`  CSV encoded response
  - `:json` - JSON encoded response (implicit default)
  - `:raw`  Raw server format (JSON string)

  ### Query Language Selection

  If not otherwise specified all queries will be sent as `InfluxQL`.
  This can be changed to `Flux` by passing the option `[query_language: :flux]`
  to `MyApp.MyConnection.execute/2`

  ### Reading Data

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

  ### POST Queries

  Some queries require you to switch from the regular `read only context`
  (all GET requets) to a `write context` (all POST requests).

  When not using the query build you have to pass that information
  manually to `execute/2`:

      "CREATE DATABASE create_in_write_mode"
      |> MyApp.MyConnection.execute(method: :post)

  ### Query Timeout Configuration

  If you find your queries running into timeouts (e.g. `:hackney` not waiting
  long enoug for a response) you can pass an option to the query call:

      MyApp.MyConnection.execute(query, timeout: 250)

  This value can also be set as a default via the `:recv_timeout` value for
  your HTTP client configuration (see `Instream.Connection.Config` for details).
  A passed configuration will take precedence over the connection configuration.

  This does not apply to write requests. They are currently only affected by
  configured `:recv_timeout` values. Setting a connection timeout enables you to have a different timeout for read and write requests.

  Write queries are run through a process pool having an additional timeout:

      config :my_app,
        MyApp.MyConnection,
          pool_timeout: 500

  This configuration will be used to wait for an available worker
  to execute a query and defaults to `5_000`.
  """
end
