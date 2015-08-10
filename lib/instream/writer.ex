defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  use Behaviour

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end


  @doc """
  Writes a point.
  """
  defcallback write(payload :: any,
                    opts    :: Keyword.t,
                    conn    :: Keyword.t) :: any
end
