defmodule Instream.ValidateTest do
  use ExUnit.Case, async: true

  alias Instream.Validate

  test "database" do
    assert "valid-dat4base-name" == Validate.database! "valid-dat4base-name"
    assert "valid_dat4base_name" == Validate.database! "valid_dat4base_name"

    assert_raise ArgumentError, fn ->
      Validate.database! "dots.not.allowed"
    end

    assert_raise ArgumentError, fn ->
      Validate.database! "special/chars\\not%allowed"
    end
  end
end
