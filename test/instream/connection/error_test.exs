defmodule Instream.Connection.ErrorTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.ConnectionWithOpts
  alias Instream.TestHelpers.UnreachableConnection


  defmodule TestSeries do
    use Instream.Series

    series do
      database    "test_database"
      measurement "connection_error_tests"

      tag :foo, default: :bar

      field :value, default: 100
    end
  end


  test "ping connection" do
    assert :error == UnreachableConnection.ping()
    assert :error == ConnectionWithOpts.ping()
  end

  test "status connection" do
    assert :error == UnreachableConnection.status()
    assert :error == ConnectionWithOpts.status()
  end

  test "version connection" do
    assert :error == UnreachableConnection.version()
    assert :error == ConnectionWithOpts.version()
  end


  test "reading data from an unresolvable host" do
    query = "SELECT * FROM connection_error_tests"

    assert { :error, :nxdomain } == UnreachableConnection.query(query)
  end

  test "writing data to an unresolvable host" do
    data = %TestSeries{}

    assert { :error, :nxdomain } == UnreachableConnection.write(data)
  end
end
