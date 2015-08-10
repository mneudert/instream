defmodule Instream.Connection.Config do
  @moduledoc """
  Configuration helper module.
  """

  @doc """
  Retrieves the connection configuration for `conn` in `otp_app`.
  """
  @spec config(otp_app :: atom, conn :: module) :: Keyword.t
  def config(otp_app, conn) do
    if config = Application.get_env(otp_app, conn) do
      ([ otp_app: otp_app ] ++ config) |> add_defaults()
    else
      raise ArgumentError,
        "configuration for #{ inspect conn } not found in #{ inspect otp_app } configuration"
    end
  end


  defp add_defaults(config) do
    config
    |> Keyword.put(:writer, config[:writer] || Instream.Writer.JSON)
  end
end
