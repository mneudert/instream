defmodule Instream.DatabaseTest do
  use ExUnit.Case, async: true

  defmodule TestDatabase do
    use Instream.Database

    database do
      name("test_database")
    end
  end

  test "database metadata" do
    assert "test_database" = TestDatabase.__meta__(:name)
  end
end
