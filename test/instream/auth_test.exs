defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  test "anonymous user connection" do
    defmodule AnonymousConnection do
      use Instream.Connection,
        config: [
          loggers: []
        ]
    end

    assert fn ->
      "SHOW DATABASES"
      |> AnonymousConnection.execute()
      |> Map.get(:error)
      |> String.contains?("Basic Auth")
    end
  end

  test "query auth connection" do
    defmodule QueryAuthConnection do
      use Instream.Connection,
        config: [
          auth: [method: :query, username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    refute (fn ->
              "SHOW DATABASES"
              |> QueryAuthConnection.execute()
              |> Map.has_key?(:error)
            end).()
  end

  test "invalid password" do
    defmodule AuthenticationFailedConnection do
      use Instream.Connection,
        config: [
          auth: [password: "instream_test", username: "instream_invalid"],
          loggers: []
        ]
    end

    assert fn ->
      "SHOW DATABASES"
      |> AuthenticationFailedConnection.execute()
      |> Map.get(:error)
      |> String.contains?("authentication failed")
    end
  end

  test "user not found" do
    defmodule NotFoundConnection do
      use Instream.Connection,
        config: [
          auth: [username: "instream_not_found", password: "instream_not_found"],
          loggers: []
        ]
    end

    assert fn ->
      "SHOW DATABASES"
      |> NotFoundConnection.execute()
      |> Map.get(:error)
      |> String.contains?("not found")
    end
  end
end
