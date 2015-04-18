defmodule Instream.ResponseTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Database
  alias Instream.TestHelpers.Connection

  test "parsed response" do
    response = Database.show() |> Connection.execute()

    assert is_map(response)
  end

  test "raw response" do
    response = Database.show() |> Connection.execute([ result_as: :raw ])

    assert is_binary(response)
  end
end
