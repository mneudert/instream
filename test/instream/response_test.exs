defmodule Instream.ResponseTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Database
  alias Instream.Response
  alias Instream.TestHelpers.Connections.DefaultConnection


  test "response format: default (parsed)" do
    response = Database.show() |> DefaultConnection.execute()

    assert is_map(response)
  end

  @tag influxdb_version: "1.1"
  test "response format: csv" do
    response = Database.show() |> DefaultConnection.execute([ result_as: :csv ])

    assert is_binary(response)
    assert "name," <> _ = response
  end

  test "response format: raw" do
    response = Database.show() |> DefaultConnection.execute([ result_as: :raw ])

    assert is_binary(response)
    assert "{" <> _ = response
  end


  test "raw json error response" do
    error    = "text"
    response = { 500, [{ "Content-Type", "application/json" }], error }

    assert error == Response.maybe_parse(response, [ result_as: :raw ])
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
