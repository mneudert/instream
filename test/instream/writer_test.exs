defmodule Instream.WriterTest do
  use ExUnit.Case, async: true

  alias Instream.Data.Read
  alias Instream.Data.Write
  alias Instream.TestHelpers.Connection
  alias Instream.TestHelpers.JSONConnection


  defmodule ErrorsSeries do
    use Instream.Series

    series do
      database    :test_database
      measurement :writer_errors

      field :binary
    end
  end

  defmodule LineEncodingSeries do
    use Instream.Series

    series do
      database    :test_database
      measurement :writer_line_encoding

      field :binary
      field :boolean
      field :float
      field :integer
    end
  end

  defmodule ProtocolsSeries do
    use Instream.Series

    series do
      database    :test_database
      measurement :writer_protocols

      tag :bar
      tag :foo

      field :value
    end
  end


  test "writer protocols" do
    data = %ProtocolsSeries{}
    data = %{ data | tags: %{ data.tags | foo: "foo", bar: "bar" }}

    # JSON protocol
    data = %{ data | fields:    %{ data.fields | value: "JSON" }}
    data = %{ data | timestamp: "2015-08-14T21:32:05Z" }

    query  = data |> Write.query()
    result = query |> JSONConnection.execute()

    assert :ok == result

    # Line (default) protocol
    data = %{ data | fields:    %{ data.fields | value: "Line" }}
    data = %{ data | timestamp: 1439587926000000000 }

    query  = data |> Write.query()
    result = query |> Connection.execute()

    assert :ok == result

    # wait to ensure data was written
    :timer.sleep(250)

    # check data
    result =
         "SELECT * FROM #{ ProtocolsSeries.__meta__(:measurement) } GROUP BY *"
      |> Read.query(precision: :nano_seconds)
      |> Connection.execute(database: ProtocolsSeries.__meta__(:database))

    assert %{ results: [%{ series: [%{
      values: [
        [ 1439587925000000000, "JSON" ],
        [ 1439587926000000000, "Line" ]
      ]
    }]}]} = result
  end


  test "line protocol data encoding" do
    data = %LineEncodingSeries{}
    data = %{ data | fields: %{ data.fields | binary:  "binary",
                                              boolean: false,
                                              float:   1.1,
                                              integer: 100 }}

    query  = data |> Write.query()
    result = query |> Connection.execute()

    assert :ok == result

    # wait to ensure data was written
    :timer.sleep(250)

    # check data
    result =
         "SELECT * FROM #{ LineEncodingSeries.__meta__(:measurement) } GROUP BY *"
      |> Read.query()
      |> Connection.execute(database: LineEncodingSeries.__meta__(:database))

    assert %{ results: [%{ series: [%{
      values: [[ _, "binary", false, 1.1, 100 ]]
    }]}]} = result
  end


  test "protocol error decoding" do
    data = %ErrorsSeries{}
    data = %{ data | fields: %{ data.fields | binary:  "binary" }}

    :ok = data |> Write.query() |> Connection.execute()

    # wait to ensure data was written
    :timer.sleep(250)

    # make entry fail
    data = %{ data | fields: %{ data.fields | binary: 12345 }}

    # JSON protocol write error
    %{ error: error } = data |> Write.query() |> JSONConnection.execute()

    assert String.contains?(error, "failed")

    # Line protocol write error
    %{ error: error } = data |> Write.query() |> Connection.execute()

    assert String.contains?(error, "failed")
  end
end
