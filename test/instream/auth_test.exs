defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Database
  alias Instream.TestHelpers.AnonConnection

  test "anonymous user connection" do
    %{ error: error } = Database.show() |> AnonConnection.execute()

    assert String.contains?(error, "Basic Auth")
  end
end
