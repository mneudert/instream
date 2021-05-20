defmodule Instream.MixProject do
  use Mix.Project

  @url_github "https://github.com/mneudert/instream"

  def project do
    [
      app: :instream,
      name: "Instream",
      version: "2.0.0-dev",
      elixir: "~> 1.7",
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
        "coveralls.detail": :test
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
      {:benchee, "~> 1.0", only: :bench, runtime: false},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.0", only: :test, runtime: false},
      {:hackney, "~> 1.1"},
      {:influxql, "~> 0.2.0"},
      {:jason, "~> 1.0"},
      {:mox, "~> 1.0", only: :test},
      {:nimble_csv, "~> 1.0"},
      {:poolboy, "~> 1.5"},
      {:ranch, "~> 1.7", only: :test}
    ]
  end

  defp dialyzer do
    [
      flags: [
        :error_handling,
        :race_conditions,
        :underspecs,
        :unmatched_returns
      ],
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_core_path: "plts",
      plt_file: {:no_warn, "plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      main: "Instream",
      source_ref: "master",
      source_url: @url_github
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [".formatter.exs", "CHANGELOG.md", "LICENSE", "mix.exs", "README.md", "lib"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @url_github}
    }
  end
end
