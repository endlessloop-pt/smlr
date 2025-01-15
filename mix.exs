defmodule Smlr.MixProject do
  use Mix.Project

  def project do
    [
      app: :smlr,
      version: "1.0.7",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/mogorman/smlr",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # Docs
      name: "Smlr",
      source_url: "https://github.com/mogorman/smlr",
      homepage_url: "https://github.com/mogorman/smlr",
      docs: [
        # The main page in the docs
        main: "Smlr",
        logo: "smlr.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Smlr.Application, []}
    ]
  end

  defp description() do
    "Smlr provides a plug for compressing dynamic content in phoenix and optionally cache the compression."
  end

  defp package() do
    [
      maintainers: ["Matthew O'Gorman mog@rldn.net"],
      links: %{"GitHub" => "https://github.com/mogorman/smlr"},
      licenses: ["MIT"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.4.0", only: [:test]},
      {:poison, "~> 3.1", only: [:test]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:plug, ">= 1.6.0"},
      {:cachex, "~> 3.0"},
      {:brotli, git: "https://github.com/yjh0502/erl-brotli", ref: "48e707f"},
      {:telemetry, "~> 0.4.1"}
    ]
  end
end
