defmodule Instream.Database.ValidatorTest do
  use ExUnit.Case, async: true

  test "missing database raises" do
    assert_raise ArgumentError, ~r/missing database/, fn ->
      defmodule MissingDatabase do
        use Instream.Database
      end
    end
  end

  test "missing name raises" do
    assert_raise ArgumentError, ~r/missing name/, fn ->
      defmodule MissingName do
        use Instream.Database

        database do
        end
      end
    end
  end
end
