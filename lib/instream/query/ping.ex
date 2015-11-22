defmodule Instream.Query.Ping do
  @moduledoc """
  Executes `:ping` queries..
  """

  use Instream.Query

  alias Instream.Query.Headers
  alias Instream.Query.URL

  def execute(_query, _opts, conn) do
    headers = conn |> Headers.assemble()

    conn
    |> URL.ping()
    |> :hackney.head(headers)
    |> parse_response()
  end


  defp parse_response({ :ok, 204, _ }), do: :pong
  defp parse_response(_),               do: :error
end
