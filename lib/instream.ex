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
  """
end
