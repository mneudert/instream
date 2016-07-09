defmodule Instream.Writer do
  @moduledoc """
  Point writer behaviour.
  """

  alias Instream.Query
  alias Instream.Response

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end


  @doc """
  Writes a point.
  """
  @callback write(payload :: Query.t,
                  opts    :: Keyword.t,
                  conn    :: map) :: Response.t
end
