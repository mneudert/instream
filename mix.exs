defmodule Instream.Mixfile do
  use Mix.Project

  @url_github "https://github.com/mneudert/instream"

  def project do
    [
      app: :instream,
      name: "Instream",
      version: "0.19.0-dev",
      elixir: "~> 1.3",
      deps: deps(),
      description: "InfluxDB driver for Elixir",
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      erlc_paths: erlc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.travis": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      applications: [:hackney, :logger, :poison, :poolboy],
      included_applications: [:influxql]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.9", only: :test},
      {:hackney, "~> 1.1"},
      {:influxql, "~> 0.1.0"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:poolboy, "~> 1.5"}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_ref: "master",
      source_url: @url_github
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  defp erlc_paths(:test), do: ["src", "test/helpers/inets"]
  defp erlc_paths(_), do: ["src"]

  defp package do
    %{
      files: [".formatter.exs", "CHANGELOG.md", "LICENSE", "mix.exs", "README.md", "lib"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @url_github},
      maintainers: ["Marc Neudert"]
    }
  end
end
