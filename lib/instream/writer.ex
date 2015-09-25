defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  @type response :: { status  :: pos_integer,
                      headers :: list,
                      body    :: String.t }


  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end


  @doc """
  Writes a point.
  """
  @callback write(payload :: any,
                  opts    :: Keyword.t,
                  conn    :: Keyword.t) :: response
end
