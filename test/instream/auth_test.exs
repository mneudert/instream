defmodule Instream.AuthTest do
  use ExUnit.Case, async: true

  @tag :"influxdb_exclude_2.0"
  test "anonymous user connection" do
    defmodule AnonymousConnection do
      use Instream.Connection,
        config: [
          loggers: []
        ]
    end

    assert %{error: "unable to parse authentication credentials"} =
             AnonymousConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "basic auth connection" do
    defmodule BasicAuthConnection do
      use Instream.Connection,
        config: [
          auth: [method: :basic, username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    assert %{results: _} = BasicAuthConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "default auth connection" do
    defmodule DefaultAuthConnection do
      use Instream.Connection,
        config: [
          auth: [username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    assert %{results: _} = DefaultAuthConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "query auth connection" do
    defmodule QueryAuthConnection do
      use Instream.Connection,
        config: [
          auth: [method: :query, username: "instream_test", password: "instream_test"],
          loggers: []
        ]
    end

    assert %{results: _} = QueryAuthConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "invalid password" do
    defmodule AuthenticationFailedConnection do
      use Instream.Connection,
        config: [
          auth: [password: "instream_test", username: "instream_invalid"],
          loggers: []
        ]
    end

    assert %{error: "authorization failed"} =
             AuthenticationFailedConnection.query("SHOW DATABASES")
  end

  @tag :"influxdb_exclude_2.0"
  test "user not found" do
    defmodule NotFoundConnection do
      use Instream.Connection,
        config: [
          auth: [username: "instream_not_found", password: "instream_not_found"],
          loggers: []
        ]
    end

    assert %{error: "authorization failed"} = NotFoundConnection.query("SHOW DATABASES")
  end
end
