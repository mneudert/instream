defmodule Instream.TestHelpers.TestSeries do
  @moduledoc """
  Test Series.
  """

  use Instream.Series

  series do
    measurement "test_series"

    tag :foo, default: :bar
    field :value, default: 100
  end
end
