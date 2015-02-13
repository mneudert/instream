defmodule Instream.PoolTest do
  use ExUnit.Case, async: true

  @otp_app    :instream_pool_test
  @otp_config []


  defmodule Conn do
    use Instream.Connection, otp_app: :instream_pool_test
  end


  setup_all do
    Application.put_env(@otp_app, Conn, @otp_config)
  end


  test "supervision" do
    Supervisor.start_link([ Conn.child_spec ], strategy: :one_for_one)

    assert Enum.any?(Process.registered, &( &1 == Conn.__pool__ ))
  end
end
