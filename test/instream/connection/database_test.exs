defmodule Instream.Connection.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.DefaultConnection

  defmodule InvalidConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        database: "invalid_test_database",
        loggers: []
      ]
  end

  defmodule DefaultSeries do
    use Instream.Series

    series do
      measurement "database_config_series"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end

  setup_all do
    conn_env = Application.get_env(:instream, InvalidConnection, [])

    Application.put_env(
      :instream,
      InvalidConnection,
      Keyword.merge(
        conn_env,
        auth: DefaultConnection.config(:auth)
      )
    )
  end

  setup do
    {:ok, _} = start_supervised(InvalidConnection)
    :ok
  end

  test "read || default: database from connection" do
    %{results: [%{error: message}]} =
      InvalidConnection.query("SELECT * FROM database_config_test")

    assert String.contains?(message, "database not found")
    assert String.contains?(message, InvalidConnection.config(:database))
  end

  test "read || opts database has priority over connection database" do
    opts = [database: "database_config_optsdb_test"]

    %{results: [%{error: message}]} =
      InvalidConnection.query("SELECT * FROM database_config_test", opts)

    assert String.contains?(message, "database not found")
    assert String.contains?(message, opts[:database])
  end

  @tag :"influxdb_exclude_2.0"
  test "write || default: database from connection" do
    %{error: message} = InvalidConnection.write(%DefaultSeries{})

    assert String.contains?(message, "database not found")
  end

  @tag :"influxdb_exclude_2.0"
  test "write || opts database has priority over connection database" do
    opts = [database: "database_config_optsdb_test"]

    %{error: message} = InvalidConnection.write(%DefaultSeries{}, opts)

    assert String.contains?(message, "database not found")
    assert String.contains?(message, opts[:database])
  end
end
