defmodule Instream.Connection do
  @moduledoc """
  Connection (pool) definition.

  All database connections will be made using a user-defined
  extension of this module.

  ## Example Module

      defmodule MyConnection do
        use Instream.Connection, otp_app: :my_application
      end

  ## Example Configuration

      config :my_application, MyConnection,
        hosts:    [ "primary.example.com", "secondary.example.com" ],
        password: "pass",
        port:     8086,
        scheme:   "http",
        username: "root"
  """

  use Behaviour

  defmacro __using__(otp_app: otp_app) do
    quote do
      @behaviour unquote(__MODULE__)
      @otp_app   unquote(otp_app)

      def config, do: Instream.Connection.Config.config(@otp_app, __MODULE__)
    end
  end

  @doc """
  Returns the connection configuration.
  """
  defcallback config :: Keyword.t
end
