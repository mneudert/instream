defmodule Instream.TestHelpers.Undeprecate do
  fun_to_charlist = case Version.compare(System.version, "1.3.0") do
    :lt -> :to_char_list
    _   -> :to_charlist
  end

  defdelegate to_charlist(data), to: String, as: fun_to_charlist
end
