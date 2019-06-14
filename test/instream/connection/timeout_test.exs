defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connections.InetsConnection

  setup_all do
    root = String.to_charlist(__DIR__)

    httpd_config = [
      document_root: root,
      modules: [Instream.TestHelpers.Inets.Handler],
      port: 0,
      server_name: 'instream_testhelpers_inets_handler',
      server_root: root
    ]

    {:ok, httpd_pid} = :inets.start(:httpd, httpd_config)

    inets_env =
      :instream
      |> Application.get_env(InetsConnection)
      |> Keyword.put(:port, :httpd.info(httpd_pid)[:port])

    Application.put_env(:instream, InetsConnection, inets_env)

    on_exit(fn ->
      :inets.stop(:httpd, httpd_pid)
    end)
  end

  test "timeout" do
    timeout = 10

    opts = [
      database: "timeout",
      timeout: timeout
    ]

    assert {:error, :timeout} == InetsConnection.query("", opts)
  end

  test "timeout above GenServer defaults" do
    timeout = 7500

    opts = [
      database: "timeout_long",
      timeout: timeout
    ]

    assert {:error, :timeout} == InetsConnection.query("", opts)
  end
end
