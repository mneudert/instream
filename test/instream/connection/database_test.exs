defmodule Instream.Connection.DatabaseTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.InvalidDbConnection


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
end
