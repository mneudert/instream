defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

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
                  conn    :: Keyword.t) :: any
end
