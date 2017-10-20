defmodule Instream.Admin.DiagnosticsTest do
  use ExUnit.Case, async: true

  alias Instream.Admin.Diagnostics
  alias Instream.TestHelpers.Connections.DefaultConnection

  test "diagnostics listing" do
    result = Diagnostics.show() |> DefaultConnection.execute()

    %{results: [%{series: diagnostics}]} = result

    assert %{name: _, columns: _, values: _} = hd(diagnostics)
  end
end
