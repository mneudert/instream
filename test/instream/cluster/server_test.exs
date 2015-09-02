defmodule Instream.Cluster.ServerTest do
  use ExUnit.Case, async: true

  alias Instream.Cluster.Server
  alias Instream.TestHelpers.Connection

  test "server listing" do
    result = Server.show() |> Connection.execute()

    %{ results: [%{ series: [%{ values: [[_, conn, _]] }]}]} = result

    assert String.contains?(conn, "localhost")
  end
end
