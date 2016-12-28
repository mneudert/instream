defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config
  alias Instream.TestHelpers.Connection, as: TestConnection
  alias Instream.TestHelpers.EnvConnection


  test "missing configuration raises", %{ test: test } do
    exception = assert_raise ArgumentError, fn ->
      Config.validate!(test, __MODULE__)
    end

    assert String.contains?(exception.message, inspect __MODULE__)
    assert String.contains?(exception.message, inspect test)
  end

  test "runtime configuration changes", %{ test: test } do
    conn = Module.concat([ __MODULE__, RuntimeChanges ])
    key  = :runtime_testing_key

    Application.put_env(test, conn, [])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    refute Keyword.has_key?(conn.config(), key)

    Application.put_env(test, conn, Keyword.put(conn.config(), key, :exists))

    assert :exists == Keyword.get(conn.config(), key)
  end


  test "default value access", %{ test: test } do
    assert "http" == Config.runtime(test, __MODULE__, nil) |> Keyword.get(:scheme)
    assert nil    == Config.runtime(test, __MODULE__, [ :auth, :username ])

    assert "http"          == TestConnection.config() |> Keyword.get(:scheme)
    assert "instream_test" == TestConnection.config([ :auth, :username ])
  end


  test "deep configuration access" do
    assert is_list(TestConnection.config())

    assert :instream       == TestConnection.config([ :otp_app ])
    assert "instream_test" == TestConnection.config([ :auth, :username ])

    assert nil == TestConnection.config([ :key_without_value ])
  end

  test "static otp_app configuration access", %{ test: test } do
    assert :instream == TestConnection.config([ :otp_app ])

    # not intended to be used this way!
    assert test == Config.runtime(test, nil, [ :otp_app ])
  end

  test "system configuration access", %{ test: test } do
    conn    = Module.concat([ __MODULE__, SystemConfiguration ])
    key     = :system_testing_key
    sys_val = "fetch from system environment"
    sys_var = "INSTREAM_TEST_CONFIG"

    System.put_env(sys_var, sys_val)
    Application.put_env(test, conn, [{ key, { :system, sys_var }}])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    assert sys_val == conn.config([ key ])
    assert sys_val == conn.config() |> get_in([ key ])

    System.delete_env(sys_var)
  end

  test "system configuration connection" do
    assert nil == EnvConnection.config([ :host ])

    host = System.get_env("INSTREAM_HOST") || "localhost"

    System.put_env("INSTREAM_TEST_HOST", host)
    System.put_env("INSTREAM_TEST_PASSWORD", "instream_test")
    System.put_env("INSTREAM_TEST_USERNAME", "instream_test")

    assert host == EnvConnection.config([ :host ])
    assert :pong == EnvConnection.ping()

    System.delete_env("INSTREAM_TEST_HOST")
    System.delete_env("INSTREAM_TEST_PASSWORD")
    System.delete_env("INSTREAM_TEST_USERNAME")
  end
end
