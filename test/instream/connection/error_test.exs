defmodule Instream.Connection.ErrorTest do
  use ExUnit.Case, async: true

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


  test "writing data to an unresolvable host" do
    data = %TestSeries{}

    assert { :error, :nxdomain } == UnreachableConnection.write(data)
  end
end
