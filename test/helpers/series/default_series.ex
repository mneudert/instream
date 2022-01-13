defmodule Instream.TestHelpers.Series.DefaultSeries do
  @moduledoc """
  Test Series.
  """

  use Instream.Series

  series do
    measurement "default_series"

    tag :foo, default: :bar
    field :value, default: 100
  end
end
