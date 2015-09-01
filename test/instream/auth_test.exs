defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.TestHelpers.AnonConnection
  alias Instream.TestHelpers.InvalidConnection
  alias Instream.TestHelpers.NotFoundConnection
  alias Instream.TestHelpers.QueryAuthConnection


  test "anonymous user connection" do
    %{ error: error } = Database.show() |> AnonConnection.execute()

    assert String.contains?(error, "Basic Auth")
  end

  test "query auth connection" do
    result = Database.show() |> QueryAuthConnection.execute()

    refute Map.has_key?(result, :error)
  end

  test "invalid password" do
    %{ error: error } = Database.show() |> InvalidConnection.execute()

    assert String.contains?(error, "authentication failed")
  end

  test "user not found" do
    %{ error: error } = Database.show() |> NotFoundConnection.execute()

    assert String.contains?(error, "not found")
  end
end
