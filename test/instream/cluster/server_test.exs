defmodule Instream.Cluster.ServerTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Server
  alias Instream.TestHelpers.Connection

  test "server listing" do
    result = Server.show() |> Connection.execute()

    %{ results: [%{ series: [%{ values: [[_, http_addr, tcp_addr,]] } | _]}]} = result

    assert String.contains?(http_addr, "localhost")
    assert String.contains?(tcp_addr, "localhost")
  end
end
