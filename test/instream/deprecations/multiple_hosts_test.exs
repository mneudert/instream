defmodule Instream.Deprecations.MultipleHostsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    config = [ hosts: [ "localhost" ]]

    Application.put_env(:instream_test, __MODULE__.DeprecatedMultipleHosts, config)

    on_exit fn ->
      Application.delete_env(:instream_test, __MODULE__.DeprecatedMultipleHosts)
    end
  end

  test "multiple hosts in configuration" do
    message = capture_io :stderr, fn ->
      defmodule DeprecatedMultipleHosts do
        use Instream.Connection, otp_app: :instream_test
      end
    end

    assert String.contains?(message, "deprecated")
  end
end
