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
        pool:     [ max_overflow: 10, size: 5 ],
        port:     8086,
        scheme:   "http",
        username: "root"
  """

  use Behaviour

  defmacro __using__(otp_app: otp_app) do
    quote do
      @before_compile unquote(__MODULE__)

      alias Instream.Connection
      alias Instream.Pool
      alias Instream.Query

      @behaviour unquote(__MODULE__)
      @otp_app   unquote(otp_app)

      def __pool__, do: __MODULE__.Pool

      def child_spec, do: Pool.Spec.spec(__MODULE__)
      def config,     do: Connection.Config.config(@otp_app, __MODULE__)

      def execute(%Query{} = query, opts \\ []) do
        case opts[:async] do
          true -> execute_async(query, opts)
          _    -> execute_sync(query, opts)
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defp execute_async(query, opts) do
        :poolboy.transaction(
          __pool__,
          &GenServer.cast(&1, { :execute, query, opts })
        )

        :ok
      end

      defp execute_sync(query, opts) do
        :poolboy.transaction(
          __pool__,
          &GenServer.call(&1, { :execute, query, opts })
        )
      end
    end
  end


  @doc """
  Returns the (internal) pool module.
  """
  defcallback __pool__ :: module

  @doc """
  Returns a supervisable pool child_spec.
  """
  defcallback child_spec :: Supervisor.Spec.spec

  @doc """
  Returns the connection configuration.
  """
  defcallback config :: Keyword.t

  @doc """
  Executes a query.

  Passing `[async: true]` in the options always returns :ok.
  The command will be executed asynchronously.
  """
  defcallback execute(query :: Instream.Query.t, opts :: Keyword.t) :: any
end
