defmodule Instream.Series do
  @moduledoc """
  Defines a series.

  ## Usage

      defmodule MySeries
        use Instream.Series

        series do
          measurement :cpu_load

          tag :host
          tag :core

          field :value
        end
      end

  ## Metadata

  The metadata of a series (i.e. the measurement) can
  be retrieved using the `__meta__/1` method.
  """

  use Behaviour

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [ series: 1 ]

      @behaviour unquote(__MODULE__)
    end
  end

  @doc """
  Provides metadata access for a series.

  ## Available information

  - `:fields`      - the fields in the series
  - `:measurement` - the measurement of the series
  - `:tags`        - the available tags defining the series
  """
  defcallback __meta__(atom) :: any


  @doc """
  Defines the series.
  """
  defmacro series(do: block) do
    quote do
      @measurement nil

      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :tags, accumulate: true)

      try do
        # scoped import
        import unquote(__MODULE__)
        unquote(block)
      after
        :ok
      end

      @fields_r @fields |> Enum.reverse()
      @tags_r   @tags   |> Enum.reverse()

      def __meta__(:fields),      do: @fields_r
      def __meta__(:measurement), do: @measurement
      def __meta__(:tags),        do: @tags_r
    end
  end


  @doc """
  Defines a field in the series.
  """
  defmacro field(name) do
    quote do
      unquote(__MODULE__).__attribute__(__MODULE__, :fields, unquote(name))
    end
  end

  @doc """
  Defines the measurement of the series.
  """
  defmacro measurement(name) do
    quote do
      unquote(__MODULE__).__attribute__(__MODULE__, :measurement, unquote(name))
    end
  end

  @doc """
  Defines a tag in the series.
  """
  defmacro tag(name) do
    quote do
      unquote(__MODULE__).__attribute__(__MODULE__, :tags, unquote(name))
    end
  end


  @doc false
  def __attribute__(mod, name, value) do
    Module.put_attribute(mod, name, value)
  end
end
