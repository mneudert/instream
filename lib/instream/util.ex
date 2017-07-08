defmodule Instream.Util do
  @moduledoc false

  # compatibility hack for elixir 1.2.x
  if Version.match?(System.version, "~> 1.2.0") do
    @doc false
    def to_charlist(string), do: String.to_char_list(string)
  else
    @doc false
    def to_charlist(string), do: String.to_charlist(string)
  end
end
