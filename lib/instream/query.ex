defmodule Instream.Query do
  @moduledoc """
  Query behaviour and struct definition.
  """

  defstruct [
    payload: nil,
    type:    nil
  ]

  @type payload_type :: String.t
  @type query_type   :: :cluster | :read | :write

  @type t :: %__MODULE__{
    payload: payload_type,
    type:    query_type
  }


  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)

      @behaviour unquote(__MODULE__)

      defdelegate maybe_parse(response, opts), to: Instream.Response
    end
  end


  @doc """
  Executes the query.
  """
  @callback execute(query :: __MODULE__.t,
                    opts  :: Keyword.t,
                    conn  :: Keyword.t) :: any

  @doc """
  Parses the query response.
  """
  @callback maybe_parse(response :: any, opts :: Keyword.t) :: any
end
