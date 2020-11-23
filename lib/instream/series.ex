defmodule Instream.Series do
  @moduledoc """
  Defines a series.

  ## Series Definition

  If you do not want to define the raw maps for writing data you can
  pre-define a series module for later usage:

      defmodule MySeries.InfluxDBv1 do
        use Instream.Series

        series do
          database "my_database_optional"

          measurement "cpu_load"

          tag :host, default: "www"
          tag :core

          field :value, default: 100
          field :value_desc
        end
      end

      defmodule MySeries.InfluxDBv2 do
        use Instream.Series

        series do
          bucket "my_bucket_optional"
          org "my_org_optional"

          measurement "cpu_load"

          tag :host, default: "www"
          tag :core

          field :value, default: 100
          field :value_desc
        end
      end

  The macros `tag/2` and `field/2` both accept a keyword tuple with a
  `:default` entry. This value will be pre-assigned when using the data
  struct with all other fields or tags being set to `nil`.

  ## Metadata

  The metadata of a series (e.g. the measurement) can
  be retrieved using the `__meta__/1` method.

  ## Struct

  Every series will be registered as a struct.
  Following the above usage example you will get the following struct:

      %MySeries{
        fields: %MySeries.Fields{value: 100, value_desc: nil},
        tags: %MySeries.Tags{host: "www", core: nil},
        timestamp: nil
      }

  `:timestamp` is expected to be a unix nanosecond timestamp.

  ## Series Hydration

  Whenever you want to convert a plain map or a query result into a specific
  series you can use the built-in hydration methods:

      MySeries.from_map(%{
        timestamp: 1234567890,
        some_tag: "hydrate",
        some_field: 123
      })

      ~S("SELECT * FROM "my_measurement")
      |> MyConnection.query()
      |> MySeries.from_result()

  The timestamp itself is kept "as is" for integer values, timestamps in
  RFC3339 format (e.g. `"1970-01-01T01:00:00.000+01:00"`) will be converted
  to `:nanosecond` integer values.

  Please be aware that when using an `OTP` release prior to `21.0` the time
  will be truncated to `:microsecond` precision due to
  `:calendar.rfc3339_to_system_time/2` not being available and
  `DateTime.from_iso8601/1` only supporting microseconds.

  ## Writing Series Points

  You can then use your series module to assemble a data point (one at a time)
  for writing:

      data = %MySeries{}
      data = %{data | fields: %{data.fields | value: 17}}
      data = %{data | tags: %{data.tags | bar: "bar", foo: "foo"}}

  And then write one or many at once:

      MyConnection.write(point)
      MyConnection.write([point_1, point_2, point_3])

  If you want to pass an explicit timestamp you can use the key `:timestamp`:

      data = %MySeries{}
      data = %{data | timestamp: 1439587926000000000}

  The timestamp is (by default) expected to be a nanosecond unix timestamp.
  To use different precision (for all points in this write operation!) you can
  change this value by modifying your write call:

      data = %MySeries{}
      data = %{data | timestamp: 1439587926}

      MyConnection.write(data, precision: :second)

  Supported precision types are:

  - `:hour`
  - `:minute`
  - `:second`
  - `:millisecond`
  - `:microsecond`
  - `:nanosecond`

  Please be aware that the UDP protocol writer does not support custom
  timestamp precisions. All UDP timestamps are implicitly expected to already
  be at nanosecond precision.

  _Note:_ While it is possible to write multiple points a once it is currently
  not supported to write them to individual databases/buckets. The first point
  written defines the database/bucket, other values are silently ignored!
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
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro series(do: block) do
    quote do
      @behaviour unquote(__MODULE__)

      @bucket nil
      @database nil
      @org nil

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

      def __meta__(:bucket), do: @bucket
      def __meta__(:database), do: @database
      def __meta__(:org), do: @org

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

      def from_map(data), do: Hydrator.from_map(__MODULE__, data)
      def from_result(data), do: Hydrator.from_result(__MODULE__, data)
    end
  end

  @doc """
  Provides metadata access for a series.

  ## Available information

  - `:bucket` - the bucket where the series is stored (optional)
  - `:database` - the database where the series is stored (optional)
  - `:fields` - the fields in the series
  - `:measurement` - the measurement of the series
  - `:org` - the organization the `:bucket` belongs to (optional)
  - `:tags` - the available tags defining the series
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
  Defines the bucket for the series.
  """
  defmacro bucket(name) do
    quote do
      @bucket unquote(name)
    end
  end

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
  Defines the organization for the series.
  """
  defmacro org(name) do
    quote do
      @org unquote(name)
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
