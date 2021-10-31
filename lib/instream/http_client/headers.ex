defmodule Instream.HTTPClient.Headers do
  @moduledoc false

  @doc """
  Returns the first header by name if available.

  Header name to find is expected to be lowercase.
  """
  @spec find(binary, [{binary, binary}]) :: binary | nil
  def find(_, []), do: nil

  def find(name, [{header, val} | headers]) do
    if name == String.downcase(header) do
      val
    else
      find(name, headers)
    end
  end
end
