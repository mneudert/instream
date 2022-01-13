defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config
  alias Instream.TestHelpers.TestConnection

  test "default value access", %{test: test} do
    assert "http" = Config.get(test, __MODULE__, :scheme, [])
    assert "http" = TestConnection.config(:scheme)
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
end
