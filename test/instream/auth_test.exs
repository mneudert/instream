defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  test "anonymous user connection" do
    defmodule AnonymousConnection do
      use Instream.Connection,
        config: [
          loggers: []
        ]
    end

    assert %{error: "unable to parse authentication credentials"} =
             AnonymousConnection.execute("SHOW DATABASES")
  end

  test "basic auth connection" do
    defmodule BasicAuthConnection do
      use Instream.Connection,
        config: [
          auth: [method: :basic, username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    assert %{results: _} = BasicAuthConnection.execute("SHOW DATABASES")
  end

  test "query auth connection" do
    defmodule QueryAuthConnection do
      use Instream.Connection,
        config: [
          auth: [method: :query, username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    assert %{results: _} = QueryAuthConnection.execute("SHOW DATABASES")
  end

  test "invalid password" do
    defmodule AuthenticationFailedConnection do
      use Instream.Connection,
        config: [
          auth: [password: "instream_test", username: "instream_invalid"],
          loggers: []
        ]
    end

    assert %{error: "authorization failed"} =
             AuthenticationFailedConnection.execute("SHOW DATABASES")
  end

  test "user not found" do
    defmodule NotFoundConnection do
      use Instream.Connection,
        config: [
          auth: [username: "instream_not_found", password: "instream_not_found"],
          loggers: []
        ]
    end

    assert %{error: "authorization failed"} = NotFoundConnection.execute("SHOW DATABASES")
  end
end
