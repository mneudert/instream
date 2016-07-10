defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config
  alias Instream.TestHelpers.Connection, as: TestConnection


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


  test "deep configuration access" do
    assert is_list(TestConnection.config())

    assert :instream       == TestConnection.config([ :otp_app ])
    assert "instream_test" == TestConnection.config([ :auth, :username ])

    assert nil == TestConnection.config([ :key_without_value ])
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

    System.delete_env(sys_var)
  end
end
