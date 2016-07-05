defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config

  test "missing configuration raises", %{ test: test } do
    exception = assert_raise ArgumentError, fn ->
      Config.validate!(test, __MODULE__)
    end

    assert String.contains?(exception.message, inspect __MODULE__)
    assert String.contains?(exception.message, inspect test)
  end
end
