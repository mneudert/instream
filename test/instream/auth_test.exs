defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.TestHelpers.AnonConnection
  alias Instream.TestHelpers.InvalidConnection

  test "anonymous user connection" do
    %{ error: error } = Database.show() |> AnonConnection.execute()

    assert String.contains?(error, "Basic Auth")
  end

  test "invalid password" do
    %{ error: error } = Database.show() |> InvalidConnection.execute()

    assert String.contains?(error, "password")
  end
end
