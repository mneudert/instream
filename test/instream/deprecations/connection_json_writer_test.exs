defmodule Instream.Deprecations.ConnectionJSONWriterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    config = [ hosts: [ "localhost" ], writer: Instream.Writer.JSON ]

    Application.put_env(:instream_test, __MODULE__.DeprecatedJSONWriter, config)

    on_exit fn ->
      Application.delete_env(:instream_test, __MODULE__.DeprecatedJSONWriter)
    end
  end

  test "json protocol writer" do
    message = capture_io :stderr, fn ->
      defmodule DeprecatedJSONWriter do
        use Instream.Connection, otp_app: :instream_test
      end
    end

    assert String.contains?(message, "deprecated")
  end
end
