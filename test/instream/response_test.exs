defmodule Instream.ResponseTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.Response
  alias Instream.TestHelpers.Connection


  test "parsed response" do
    response = Database.show() |> Connection.execute()

    assert is_map(response)
  end

  test "raw response" do
    response = Database.show() |> Connection.execute([ result_as: :raw ])

    assert is_binary(response)
  end


  test "raw non-json error response" do
    error    = "text"
    response = { 500, [], error }

    assert error == Response.maybe_parse(response, [ result_as: :raw ])
  end

  test "regular non-json response" do
    response = "text"

    assert response == Response.maybe_parse({ 200, [], response }, [])
  end
end
