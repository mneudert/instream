defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.TestHelpers.AnonConnection
  alias Instream.TestHelpers.InvalidConnection
  alias Instream.TestHelpers.NotFoundConnection


  test "anonymous user connection" do
    %{ error: error } = Database.show() |> AnonConnection.execute()

    assert String.contains?(error, "Basic Auth")
  end

  test "invalid password" do
    %{ error: error } = Database.show() |> InvalidConnection.execute()

    assert String.contains?(error, "password")
  end

  test "user not found" do
    %{ error: error } = Database.show() |> NotFoundConnection.execute()

    assert String.contains?(error, "not found")
  end
end
