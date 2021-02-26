defmodule Instream.Connection.TimeoutTest do
  use ExUnit.Case, async: true

  defmodule InetsConnection do
    use Instream.Connection,
      otp_app: :instream,
      config: [
        loggers: []
      ]
  end

  defmodule InetsHandler do
    require Record

    Record.defrecord(:mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl"))

    def unquote(:do)(mod_data), do: serve_uri(mod(mod_data, :request_uri), mod_data)

    defp serve_uri('/query?db=timeout', _mod_data) do
      :timer.sleep(100)
      serve_dummy()
    end

    defp serve_dummy do
      body = '{"results": [{}]}'

      head = [
        code: 200,
        content_length: body |> length() |> String.to_charlist(),
        content_type: 'application/json'
      ]

      {:proceed, [{:response, {:response, head, body}}]}
    end
  end

  setup_all do
    root = String.to_charlist(__DIR__)

    httpd_config = [
      document_root: root,
      modules: [InetsHandler],
      port: 0,
      server_name: 'instream_connection_timeout_test',
      server_root: root
    ]

    {:ok, httpd_pid} = :inets.start(:httpd, httpd_config)

    Application.put_env(:instream, InetsConnection, port: :httpd.info(httpd_pid)[:port])

    on_exit(fn ->
      :inets.stop(:httpd, httpd_pid)
    end)
  end

  test "timeout" do
    timeout = 10

    opts = [
      database: "timeout",
      http_opts: [recv_timeout: timeout]
    ]

    assert {:error, :timeout} = InetsConnection.query("", opts)
  end
end
