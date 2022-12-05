defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Instream.Connection.Config
  alias Instream.TestHelpers.TestConnection

  defmodule MissingOTPConfiguration do
    use Instream.Connection, otp_app: :instream
  end

  test "default value access", %{test: test} do
    assert "http" = Config.get(test, __MODULE__, :scheme, [])
    assert "http" = MissingOTPConfiguration.config(:scheme)
  end

  test "inline configuration defaults" do
    conn = Module.concat([__MODULE__, DefaultConfig])
    key = :inline_config_key

    Application.put_env(:instream, conn, [])

    defmodule conn do
      use Instream.Connection,
        otp_app: :instream,
        config: [{key, "inline value"}]
    end

    assert "inline value" = conn.config(key)

    Application.put_env(:instream, conn, Keyword.put(conn.config(), key, "runtime value"))

    assert "runtime value" = conn.config(key)
  end

  describe "validate config" do
    test "successful" do
      assert Config.validate(TestConnection)
    end

    test "missing otp app" do
      log =
        capture_log(fn ->
          refute Config.validate(MissingOTPConfiguration)

          Logger.flush()
        end)

      assert String.contains?(log, "MissingOTPConfiguration")
      assert String.contains?(log, ":instream")
      assert String.contains?(log, "configuration is empty")
    end
  end
end
