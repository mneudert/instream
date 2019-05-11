defmodule Instream.Series do
  @moduledoc """
  Defines a series.

  ## Usage

      defmodule MySeries do
        use Instream.Series

        series do
          database    "my_database_optional"
          measurement "cpu_load"

          tag :host, default: "www"
          tag :core

          field :value, default: 100
          field :value_desc
        end
      end

  ## Metadata

  The metadata of a series (e.g. the measurement) can
  be retrieved using the `__meta__/1` method.

  ## Struct

  Every series will be registered as a struct.
  Following the above usage example you will get the following struct:

      %MySeries{
        fields:    %MySeries.Fields{ value: 100, value_desc: nil },
        tags:      %MySeries.Tags{ host: "www", core: nil },
        timestamp: nil
      }

  `:timestamp` is expected to be a unix nanosecond timestamp.
  """

  alias Instream.Series.Hydrator
  alias Instream.Series.Validator

  defmacro __using__(_opts) do
    quote do
      @after_compile unquote(__MODULE__)

      import unquote(__MODULE__), only: [series: 1]
    end
  end

  defmacro __after_compile__(%{module: module}, _bytecode) do
    Validator.proper_series?(module)
  end

  @doc """
  Defines the series.
  """
  defmacro series(do: block) do
    quote do
      @behaviour unquote(__MODULE__)

      @database nil
      @measurement nil

      Module.register_attribute(__MODULE__, :fields_raw, accumulate: true)
      Module.register_attribute(__MODULE__, :tags_raw, accumulate: true)

      try do
        # scoped import
        import unquote(__MODULE__)
        unquote(block)
      after
        :ok
      end

      @fields_names @fields_raw |> Keyword.keys() |> Enum.sort()
      @fields_struct @fields_raw |> Enum.sort(&unquote(__MODULE__).__sort_fields__/2)

      @tags_names @tags_raw |> Keyword.keys() |> Enum.sort()
      @tags_struct @tags_raw |> Enum.sort(&unquote(__MODULE__).__sort_tags__/2)

      def __meta__(:database), do: @database
      def __meta__(:fields), do: @fields_names
      def __meta__(:measurement), do: @measurement
      def __meta__(:tags), do: @tags_names

      Module.eval_quoted(__ENV__, [
        unquote(__MODULE__).__struct_fields__(@fields_struct),
        unquote(__MODULE__).__struct_tags__(@tags_struct)
      ])

      Module.eval_quoted(__ENV__, [
        unquote(__MODULE__).__struct__(__MODULE__)
      ])

      def from_map(data) do
        Hydrator.from_map(__MODULE__, data)
      end

      def from_result(data) do
        Hydrator.from_result(__MODULE__, data)
      end
    end
  end

  @doc """
  Provides metadata access for a series.

  ## Available information

  - `:database`    - the database where the series is stored (optional)
  - `:fields`      - the fields in the series
  - `:measurement` - the measurement of the series
  - `:tags`        - the available tags defining the series
  """
  @callback __meta__(atom) :: any

  @doc """
  Creates a series dataset from any given map.

  Keys not defined in the series are silently dropped.
  """
  @callback from_map(map) :: struct

  @doc """
  Creates a list of series datasets from a query result map.

  Keys not defined in the series are silently dropped.
  """
  @callback from_result(map) :: [struct]

  @doc """
  Defines the database for the series.
  """
  defmacro database(name) do
    quote do
      @database unquote(name)
    end
  end

  @doc """
  Defines a field in the series.
  """
  defmacro field(name, opts \\ []) do
    quote do
      @fields_raw {unquote(name), unquote(opts[:default])}
    end
  end

  @doc """
  Defines the measurement of the series.
  """
  defmacro measurement(name) do
    quote do
      @measurement unquote(name)
    end
  end

  @doc """
  Defines a tag in the series.
  """
  defmacro tag(name, opts \\ []) do
    quote do
      @tags_raw {unquote(name), unquote(opts[:default])}
    end
  end

  @doc false
  def __sort_fields__({left, _}, {right, _}), do: left > right

  @doc false
  def __sort_tags__({left, _}, {right, _}), do: left > right

  @doc false
  def __struct__(series) do
    quote do
      @type t :: %unquote(series){
              fields: unquote(series).Fields.t(),
              tags: unquote(series).Tags.t(),
              timestamp: non_neg_integer
            }

      defstruct fields: %unquote(series).Fields{},
                tags: %unquote(series).Tags{},
                timestamp: nil
    end
  end

  @doc false
  def __struct_fields__(fields) do
    quote do
      defmodule Fields do
        @moduledoc false

        @type t :: %__MODULE__{}

        defstruct unquote(Macro.escape(fields))
      end
    end
  end

  @doc false
  def __struct_tags__(tags) do
    quote do
      defmodule Tags do
        @moduledoc false

        @type t :: %__MODULE__{}

        defstruct unquote(Macro.escape(tags))
      end
    end
  end
end
