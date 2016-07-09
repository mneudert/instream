defmodule Instream.Query.Headers do
  @moduledoc """
  Header Utility.
  """

  @doc """
  Assembles the headers for a query.
  """
  @spec assemble(Keyword.t) :: list
  def assemble(config) do
    assemble_auth(config[:auth])
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
      [{'Authorization', 'Basic dXNlcjpwYXNz'}]
  """
  @spec assemble_auth(Keyword.t) :: list
  def assemble_auth(nil), do: []
  def assemble_auth(auth) do
    case auth[:method] do
      :query -> []
      _      -> basic_auth_header(auth[:username], auth[:password])
    end
  end


  defp basic_auth_header(nil,  _),   do: []
  defp basic_auth_header(_,    nil), do: []
  defp basic_auth_header(user, pass) do
    credentials = "#{ user }:#{ pass }" |> Base.encode64
    header      = "Basic #{ credentials }" |> to_char_list()

    [{ 'Authorization', header }]
  end
end
