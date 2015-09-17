defmodule Instream.Response do
  @moduledoc """
  Response handling module.
  """

  @doc """
  Maybe parses a response based on the requested result type.
  """
  @spec maybe_parse(String.t, Keyword.t) :: any
  def maybe_parse("", _), do: :ok

  def maybe_parse(response, opts) do
    case opts[:result_as] do
      :raw -> response
      _    -> response |> Poison.decode!(keys: :atoms)
    end
  end
end
