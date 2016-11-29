defmodule Instream.Connection.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.InvalidDbConnection


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


  test "default: database from connection" do
    %{ error: message } = InvalidDbConnection.write(%NoDatabaseSeries{})

    assert String.contains?(message, "database not found")
    assert String.contains?(message, InvalidDbConnection.config([ :database ]))
  end

  test "series database has priority over connection database" do
    %{ error: message } = InvalidDbConnection.write(%DatabaseSeries{})

    assert String.contains?(message, "database not found")
    assert String.contains?(message, DatabaseSeries.__meta__(:database))
    refute String.contains?(message, InvalidDbConnection.config([ :database ]))
  end
end
