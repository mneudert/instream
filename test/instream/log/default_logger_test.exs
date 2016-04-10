defmodule Instream.Log.DefaultLoggerTest do
  use ExUnit.Case, async: true

  alias Instream.Log.PingEntry
  alias Instream.Log.QueryEntry
  alias Instream.Log.StatusEntry
  alias Instream.Log.WriteEntry
  alias Instream.TestHelpers.Connection


  test "return logged entries" do
    assert %PingEntry{}   == Connection.__log__(%PingEntry{})
    assert %QueryEntry{}  == Connection.__log__(%QueryEntry{})
    assert %StatusEntry{} == Connection.__log__(%StatusEntry{})
    assert %WriteEntry{}  == Connection.__log__(%WriteEntry{})
  end
end
