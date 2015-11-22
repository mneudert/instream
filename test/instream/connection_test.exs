defmodule Instream.ConnectionTest do
  use ExUnit.Case, async: true

  alias Instream.TestHelpers.Connection
  alias Instream.TestHelpers.UnreachableConnection


  @otp_app    :instream_connection_test
  @otp_config [ foo: :bar ]


  defmodule TestConnection do
    use Instream.Connection, otp_app: :instream_connection_test
  end


  setup_all do
    Application.put_env(@otp_app, TestConnection, @otp_config)
  end


  test "configuration" do
    config = [ writer:  Instream.Writer.Line,
               otp_app: @otp_app ] ++ @otp_config

    assert config == TestConnection.config
  end

  test "child_spec" do
    assert { TestConnection, _, _, _, _, _ } = TestConnection.child_spec
  end


  test "ping connection" do
    assert :pong  == Connection.ping()
    assert :error == UnreachableConnection.ping()
  end
end
