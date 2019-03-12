defmodule UAInspector.Deprecations.WriterUsingMacroTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "'use Instream.Writer' generates compile time warning" do
    writer = __MODULE__.Writer

    generator = fn ->
      defmodule writer do
        use Instream.Writer

        def write(_, _, _), do: {:error, :test}
      end
    end

    warning = capture_io(:stderr, generator)

    assert String.contains?(warning, Atom.to_string(writer))
    assert warning =~ ~r/deprecated.*use.*behaviour Instream\.Writer/
  end
end
