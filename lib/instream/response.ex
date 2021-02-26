defmodule Instream.Response do
  @moduledoc """
  Response type.
  """

  @type t :: {:error, term} | {:ok, status :: pos_integer, headers :: list, body :: String.t()}
end
