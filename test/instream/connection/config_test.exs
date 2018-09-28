defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config
  alias Instream.TestHelpers.Connections.DefaultConnection
  alias Instream.TestHelpers.Connections.EnvConnection

  test "runtime configuration changes", %{test: test} do
    conn = Module.concat([__MODULE__, RuntimeChanges])
    key = :runtime_testing_key

    Application.put_env(test, conn, [])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    refute Keyword.has_key?(conn.config(), key)

    Application.put_env(test, conn, Keyword.put(conn.config(), key, :exists))

    assert :exists == Keyword.get(conn.config(), key)
  end

  test "default value access", %{test: test} do
    assert "http" == Config.runtime(test, __MODULE__, nil) |> Keyword.get(:scheme)
    assert nil == Config.runtime(test, __MODULE__, [:auth, :username])

    assert "http" == DefaultConnection.config() |> Keyword.get(:scheme)
    assert "instream_test" == DefaultConnection.config([:auth, :username])
  end

  test "deep configuration access" do
    assert is_list(DefaultConnection.config())

    assert :instream == DefaultConnection.config([:otp_app])
    assert "instream_test" == DefaultConnection.config([:auth, :username])

    assert nil == DefaultConnection.config([:key_without_value])
  end

  test "static otp_app configuration access", %{test: test} do
    assert :instream == DefaultConnection.config([:otp_app])

    # not intended to be used this way!
    assert test == Config.runtime(test, nil, [:otp_app])
  end

  test "system configuration access", %{test: test} do
    conn = Module.concat([__MODULE__, SystemConfiguration])
    key = :system_testing_key
    sys_val = "fetch from system environment"
    sys_var = "INSTREAM_TEST_CONFIG"

    System.put_env(sys_var, sys_val)
    Application.put_env(test, conn, [{key, {:system, sys_var}}])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    assert sys_val == conn.config([key])
    assert sys_val == conn.config() |> get_in([key])

    System.delete_env(sys_var)
  end

  test "system configuration access (with default)", %{test: test} do
    conn = Module.concat([__MODULE__, SystemConfigurationDefault])
    key = :system_testing_key
    default = "fetch from system environment"
    sys_var = "INSTREAM_TEST_CONFIG_DEFAULT"

    System.delete_env(sys_var)
    Application.put_env(test, conn, [{key, {:system, sys_var, default}}])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    assert default == conn.config([key])
    assert default == conn.config() |> get_in([key])
  end

  test "system configuration connection" do
    System.put_env("INSTREAM_TEST_ENV_HOST", "remotehost")

    assert "remotehost" == EnvConnection.config([:host])

    System.put_env("INSTREAM_TEST_ENV_HOST", "localhost")

    assert "localhost" == EnvConnection.config([:host])
    assert :pong == EnvConnection.ping()

    System.delete_env("INSTREAM_TEST_ENV_HOST")
  end

  test "inline configuration defaults" do
    conn = Module.concat([__MODULE__, DefaultConfig])
    key = :inline_config_key

    Application.put_env(:instream, conn, [])

    defmodule conn do
      use Instream.Connection,
        otp_app: :instream,
        config: [{:"#{key}", "inline value"}]
    end

    assert "inline value" == conn.config([key])

    Application.put_env(:instream, conn, Keyword.put(conn.config(), key, "runtime value"))

    assert "runtime value" == conn.config([key])
  end
end
