defmodule Instream.Query.Headers do
  @moduledoc false

  @doc """
  Assembles the headers for a query.
  """
  @spec assemble(Keyword.t(), Keyword.t()) :: [{binary, binary}]
  def assemble(config, options \\ []) do
    assemble_auth(config[:auth]) ++
      assemble_encoding(options[:result_as]) ++
      assemble_language(options[:query_language])
  end

  @doc """
  Assembles headers for basic authentication.

  Will return an empty list if query authentication is configured.
  Will return an empty list if either username of password is missing.

  ## Usage

      iex> assemble_auth(method: :query)
      []

      iex> assemble_auth(method: :token, token: "my-token")
      [{"Authorization", "Token my-token"}]

      iex> assemble_auth(username: "user")
      []
      iex> assemble_auth(password: "pass")
      []

      iex> assemble_auth(username: "user", password: "pass")
      [{"Authorization", "Basic dXNlcjpwYXNz"}]
  """
  @spec assemble_auth(Keyword.t()) :: [{binary, binary}]
  def assemble_auth(nil), do: []

  def assemble_auth(auth) do
    case auth[:method] do
      :query -> []
      :token -> [{"Authorization", "Token #{auth[:token]}"}]
      _ -> basic_auth_header(auth[:username], auth[:password])
    end
  end

  @doc """
  Assembles headers for response encoding.

  ## Usage

      iex> assemble_encoding(nil)
      []

      # not handled here...
      iex> assemble_encoding(:raw)
      []

      iex> assemble_encoding(:csv)
      [{"Accept", "application/csv"}]

      iex> assemble_encoding(:json)
      [{"Accept", "application/json"}]
  """
  @spec assemble_encoding(nil | :csv | :json | :raw) :: [{String.t(), String.t()}]
  def assemble_encoding(nil), do: []
  def assemble_encoding(:csv), do: [{"Accept", "application/csv"}]
  def assemble_encoding(:json), do: [{"Accept", "application/json"}]
  def assemble_encoding(:raw), do: []

  @doc """
  Assembles headers required for query language selection.

  ## Usage

      iex> assemble_language(nil)
      []

      iex> assemble_language(:flux)
      [{"Accept", "application/csv"}, {"Content-Type", "application/vnd.flux"}]
  """
  @spec assemble_language(nil | :flux) :: [{String.t(), String.t()}]
  def assemble_language(nil), do: []

  def assemble_language(:flux),
    do: [{"Accept", "application/csv"}, {"Content-Type", "application/vnd.flux"}]

  defp basic_auth_header(nil, _), do: []
  defp basic_auth_header(_, nil), do: []

  defp basic_auth_header(user, pass) do
    credentials = "#{user}:#{pass}" |> Base.encode64()
    header = "Basic #{credentials}"

    [{"Authorization", header}]
  end
end
