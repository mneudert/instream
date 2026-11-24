defmodule Instream.HTTPClient.HackneyTest do
  use ExUnit.Case, async: true

  alias Instream.HTTPClient.Hackney

  test "GET returns the response body directly" do
    with_server("200 OK", "result", fn url ->
      assert {:ok, 200, _, "result"} = Hackney.request(:get, url, [], "", [])
    end)
  end

  test "POST preserves error response bodies" do
    with_server("400 Bad Request", "invalid query", fn url ->
      assert {:ok, 400, _, "invalid query"} = Hackney.request(:post, url, [], "query", [])
    end)
  end

  test "HEAD retains the bodyless response tuple and version header" do
    with_server("204 No Content", "", fn url ->
      assert {:ok, 204, headers} = Hackney.request(:head, url, [], "", [])
      assert Instream.HTTPClient.Headers.find("x-influxdb-version", headers) == "1.8.10"
    end)
  end

  test "connection errors propagate" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, port} = :inet.port(listener)
    :ok = :gen_tcp.close(listener)
    assert {:error, _} = Hackney.request(:get, "http://127.0.0.1:#{port}", [], "", [])
  end

  defp with_server(status, body, fun) do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, port} = :inet.port(listener)

    server =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listener, 5_000)
        {:ok, _request} = :gen_tcp.recv(socket, 0, 5_000)

        :ok =
          :gen_tcp.send(
            socket,
            "HTTP/1.1 #{status}\r\nContent-Length: #{byte_size(body)}\r\n" <>
              "X-Influxdb-Version: 1.8.10\r\nConnection: close\r\n\r\n" <> body
          )

        :gen_tcp.close(socket)
      end)

    try do
      fun.("http://127.0.0.1:#{port}")
      Task.await(server)
    after
      :gen_tcp.close(listener)
    end
  end
end
