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
    |> maybe_fetch_system()
    |> maybe_use_default(keys)
  end

  defp log_system_config_deprecation do
    Logger.info(fn ->
      "Accessing the system environment for configuration via" <>
        " {:system, \"var\"} has been deprecated. Please switch" <>
        " to an initializer function to avoid future problems."
    end)
  end

  defp maybe_fetch_deep(config, nil), do: config
  defp maybe_fetch_deep(config, keys), do: get_in(config, keys)

  defp maybe_fetch_system(config) when is_list(config) do
    Enum.map(config, fn
      {k, v} -> {k, maybe_fetch_system(v)}
      other -> other
    end)
  end

  defp maybe_fetch_system({:system, var, default}) do
    _ = log_system_config_deprecation()
    System.get_env(var) || default
  end

  defp maybe_fetch_system({:system, var}) do
    _ = log_system_config_deprecation()
    System.get_env(var)
  end

  defp maybe_fetch_system(config), do: config

  defp maybe_use_default(config, nil), do: Keyword.merge(@global_defaults, config)
  defp maybe_use_default(nil, keys), do: get_in(@global_defaults, keys)
  defp maybe_use_default(config, _), do: config
end
