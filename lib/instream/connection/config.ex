defmodule Instream.Connection.Config do
  @moduledoc """
  Configuration helper module.
  """

  @defaults [
    loggers: [{ Instream.Log.DefaultLogger, :log, [] }],
    port:    8086,
    scheme:  "http",
    writer:  Instream.Writer.Line
  ]


  @doc """
  Retrieves the connection configuration for `conn` in `otp_app`.
  """
  @spec config(atom, module) :: Keyword.t
  def config(otp_app, conn) do
    @defaults
    |> Keyword.put(:otp_app, otp_app)
    |> Keyword.merge(Application.get_env(otp_app, conn, []))
  end

  @doc """
  Validates a connection configuration and raises if an error exists.
  """
  @spec validate!(atom, module) :: no_return
  def validate!(otp_app, conn) do
    if :error == Application.fetch_env(otp_app, conn) do
      raise ArgumentError, "configuration for #{ inspect conn }" <>
                           " not found in #{ inspect otp_app } configuration"
    end
  end
end
