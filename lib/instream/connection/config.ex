defmodule Instream.Connection.Config do
  @moduledoc """
  Configuration helper module.
  """

  require Logger

  @compile_time_keys [:loggers]
  @global_defaults [
    host: "localhost",
    loggers: [{Instream.Log.DefaultLogger, :log, []}],
    port: 8086,
    scheme: "http",
    writer: Instream.Writer.Line
  ]

  @doc """
  Retrieves the compile time part of the connection configuration.
  """
  @spec compile_time(atom, module, Keyword.t()) :: Keyword.t()
  def compile_time(otp_app, conn, defaults \\ []) do
    @global_defaults
    |> Keyword.merge(defaults)
    |> Keyword.merge(Application.get_env(otp_app, conn, []))
    |> Keyword.take(@compile_time_keys)
  end

  @doc """
  Retrieves the runtime connection configuration for `conn` in `otp_app`.
  """
  @spec runtime(atom, module, nil | nonempty_list(term), Keyword.t()) :: Keyword.t()
  def runtime(otp_app, conn, keys, defaults \\ [])

  def runtime(otp_app, _, [:otp_app], _), do: otp_app

  def runtime(otp_app, conn, keys, defaults) do
    defaults
    |> Keyword.merge(Application.get_env(otp_app, conn, []))
    |> maybe_fetch_deep(keys)
    |> maybe_use_default(keys)
  end

  defp maybe_fetch_deep(config, nil), do: config
  defp maybe_fetch_deep(config, keys), do: get_in(config, keys)

  defp maybe_use_default(config, nil), do: Keyword.merge(@global_defaults, config)
  defp maybe_use_default(nil, keys), do: get_in(@global_defaults, keys)
  defp maybe_use_default(config, _), do: config
end
