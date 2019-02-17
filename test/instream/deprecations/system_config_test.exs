defmodule UAInspector.Deprecations.SystemConfigTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Instream.TestHelpers.Connections.EnvConnection

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

    log =
      capture_log(fn ->
        assert sys_val == conn.config([key])
        assert sys_val == conn.config() |> get_in([key])
      end)

    Application.delete_env(:ua_inspector, :test_only)

    assert log =~ ~r/deprecated/i

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

    log =
      capture_log(fn ->
        assert default == conn.config([key])
        assert default == conn.config() |> get_in([key])
      end)

    assert log =~ ~r/deprecated/i
  end

  test "system configuration connection" do
    System.put_env("INSTREAM_TEST_ENV_HOST", "remotehost")

    log =
      capture_log(fn ->
        assert "remotehost" == EnvConnection.config([:host])
      end)

    assert log =~ ~r/deprecated/i

    System.put_env("INSTREAM_TEST_ENV_HOST", "localhost")

    log =
      capture_log(fn ->
        assert "localhost" == EnvConnection.config([:host])
        assert :pong == EnvConnection.ping()
      end)

    assert log =~ ~r/deprecated/i

    System.delete_env("INSTREAM_TEST_ENV_HOST")
  end
end
