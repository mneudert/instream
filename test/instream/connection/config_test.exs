defmodule Instream.Connection.ConfigTest do
  use ExUnit.Case, async: true

  alias Instream.Connection.Config

  test "otp_app configuration", %{ test: test } do
    config = [ foo: :bar ]
    :ok    = Application.put_env(test, __MODULE__, config)

    assert ([ otp_app: test ] ++ config) == Config.config(test, __MODULE__)
  end

  test "missing configuration raises", %{ test: test } do
    exception = assert_raise ArgumentError, fn ->
      Config.config(test, __MODULE__)
    end

    assert String.contains?(exception.message, inspect __MODULE__)
    assert String.contains?(exception.message, inspect test)
  end
end
