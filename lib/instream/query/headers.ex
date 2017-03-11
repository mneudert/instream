defmodule Instream.Query.Headers do
  @moduledoc """
  Header Utility.
  """

  @doc """
  Assembles the headers for a query.
  """
  @spec assemble(Keyword.t, Keyword.t) :: list
  def assemble(config, options \\ []) do
    assemble_auth(config[:auth])
    ++ assemble_encoding(options[:result_as])
  end

  @doc """
  Assembles headers for basic authentication.

  Will return an empty list if query authentication is configured.
  Will return an empty list if either username of password is missing.

  ## Usage

      iex> assemble_auth([ method: :query ])
      []

      iex> assemble_auth([ username: "user" ])
      []
      iex> assemble_auth([ password: "pass" ])
      []

      iex> assemble_auth([ username: "user", password: "pass" ])
      [{"Authorization", "Basic dXNlcjpwYXNz"}]
  """
  @spec assemble_auth(Keyword.t) :: list
  def assemble_auth(nil), do: []
  def assemble_auth(auth) do
    case auth[:method] do
      :query -> []
      _      -> basic_auth_header(auth[:username], auth[:password])
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
  @spec assemble_encoding(nil | atom) :: list
  def assemble_encoding(nil),   do: []
  def assemble_encoding(:csv),  do: [{ "Accept", "application/csv" }]
  def assemble_encoding(:json), do: [{ "Accept", "application/json" }]
  def assemble_encoding(:raw),  do: []


  defp basic_auth_header(nil,  _),   do: []
  defp basic_auth_header(_,    nil), do: []
  defp basic_auth_header(user, pass) do
    credentials = "#{ user }:#{ pass }" |> Base.encode64
    header      = "Basic #{ credentials }"

    [{ "Authorization", header }]
  end
end
