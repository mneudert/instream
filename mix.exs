defmodule Instream.MixProject do
  use Mix.Project

  @url_changelog "https://hexdocs.pm/instream/changelog.html"
  @url_github "https://github.com/mneudert/instream"
  @version "2.3.0-dev"

  def project do
    [
      app: :instream,
      name: "Instream",
      version: @version,
      elixir: "~> 1.9",
      aliases: aliases(),
      deps: deps(),
      description: "InfluxDB driver for Elixir",
      dialyzer: dialyzer(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      preferred_cli_env: [
        "bench.line_encoder": :bench,
        coveralls: :test,
        "coveralls.detail": :test,
        dialyzer: :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      "bench.line_encoder": ["run bench/line_encoder.exs"]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.1", only: :bench, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.15.0", only: :test, runtime: false},
      {:hackney, "~> 1.1"},
      {:influxql, "~> 0.2.0"},
      {:jason, "~> 1.0"},
      {:mox, "~> 1.0", only: :test},
      {:nimble_csv, "~> 1.0"},
      {:poolboy, "~> 1.5"},
      {:ranch, "~> 1.7.0", only: :test}
    ]
  end

  defp dialyzer do
    [
      flags: [
        :error_handling,
        :underspecs,
        :unmatched_returns
      ],
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_core_path: "plts",
      plt_local_path: "plts"
    ]
  end

  defp docs do
    [
      main: "Instream",
      extras: [
        "CHANGELOG.md",
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @url_github
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: [".formatter.exs", "CHANGELOG.md", "LICENSE", "mix.exs", "README.md", "lib"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => @url_changelog,
        "GitHub" => @url_github
      }
    ]
  end
end
