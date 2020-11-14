defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "runtime configuration changes", %{test: test} do
    conn = Module.concat([__MODULE__, RuntimeChanges])
    key = :runtime_testing_key

    Application.put_env(test, conn, [])

    defmodule conn do
      use Instream.Connection, otp_app: test
    end

    refute Keyword.has_key?(conn.config(), key)

    Application.put_env(test, conn, Keyword.put(conn.config(), key, :exists))

    assert :exists = Keyword.get(conn.config(), key)
  end

  @tag :"influxdb_exclude_1.8"
  test "default value access 1.x", %{test: test} do
    # credo:disable-for-next-line Credo.Check.Refactor.PipeChainStart
    assert "http" = Config.runtime(test, __MODULE__, nil) |> Keyword.get(:scheme)
    refute Config.runtime(test, __MODULE__, [:auth, :token])

    assert "http" = DefaultConnection.config() |> Keyword.get(:scheme)
    assert "instream_test" = DefaultConnection.config([:auth, :token])
  end

  @tag :"influxdb_exclude_2.0"
  test "default value access 2.x", %{test: test} do
    # credo:disable-for-next-line Credo.Check.Refactor.PipeChainStart
    assert "http" = Config.runtime(test, __MODULE__, nil) |> Keyword.get(:scheme)
    refute Config.runtime(test, __MODULE__, [:auth, :username])

    assert "http" = DefaultConnection.config() |> Keyword.get(:scheme)
    assert "instream_test" = DefaultConnection.config([:auth, :username])
  end

  @tag :"influxdb_exclude_1.8"
  test "deep configuration access 1.x" do
    assert is_list(DefaultConnection.config())

    assert :instream = DefaultConnection.config([:otp_app])
    assert "instream_test" = DefaultConnection.config([:auth, :token])

    refute DefaultConnection.config([:key_without_value])
  end

  @tag :"influxdb_exclude_2.0"
  test "deep configuration access 2.x" do
    assert is_list(DefaultConnection.config())

    assert :instream = DefaultConnection.config([:otp_app])
    assert "instream_test" = DefaultConnection.config([:auth, :username])

    refute DefaultConnection.config([:key_without_value])
  end

  test "static otp_app configuration access", %{test: test} do
    assert :instream = DefaultConnection.config([:otp_app])

    # not intended to be used this way!
    assert ^test = Config.runtime(test, nil, [:otp_app])
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

    assert "inline value" = conn.config([key])

    Application.put_env(:instream, conn, Keyword.put(conn.config(), key, "runtime value"))

    assert "runtime value" = conn.config([key])
  end
end
