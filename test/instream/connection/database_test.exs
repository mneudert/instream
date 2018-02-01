defmodule Instream.Connection.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.InvalidDbConnection

  defmodule DatabaseSeries do
    use Instream.Series

    series do
      database "database_config_seriesdb_test"
      measurement "database_config_seriesdb_test"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end

  defmodule NoDatabaseSeries do
    use Instream.Series

    series do
      measurement "database_config_nodb_test"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end

  test "read || default: database from connection" do
    %{results: [%{error: message}]} =
      InvalidDbConnection.execute("SELECT * FROM database_config_test")

    assert String.contains?(message, "database not found")
    assert String.contains?(message, InvalidDbConnection.config([:database]))
  end

  test "read || opts database has priority over connection database" do
    opts = [database: "database_config_optsdb_test"]

    %{results: [%{error: message}]} =
      InvalidDbConnection.execute("SELECT * FROM database_config_test", opts)

    assert String.contains?(message, "database not found")
    assert String.contains?(message, opts[:database])
    refute String.contains?(message, InvalidDbConnection.config([:database]))
  end

  test "write || default: database from connection" do
    %{error: message} = InvalidDbConnection.write(%NoDatabaseSeries{})

    assert String.contains?(message, "database not found")
    assert String.contains?(message, InvalidDbConnection.config([:database]))
  end

  test "write || series database has priority over connection database" do
    %{error: message} = InvalidDbConnection.write(%DatabaseSeries{})

    assert String.contains?(message, "database not found")
    assert String.contains?(message, DatabaseSeries.__meta__(:database))
    refute String.contains?(message, InvalidDbConnection.config([:database]))
  end

  test "write || opts database has priority over series database" do
    opts = [database: "database_config_optsdb_test"]

    %{error: message} = InvalidDbConnection.write(%DatabaseSeries{}, opts)

    assert String.contains?(message, "database not found")
    assert String.contains?(message, opts[:database])
    refute String.contains?(message, DatabaseSeries.__meta__(:database))
  end
end
