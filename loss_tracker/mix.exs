defmodule LossTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :loss_tracker,
      version: "0.0.1",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LossTracker.Application, []}
    ]
  end

  defp description do
    """
    Plugs Demystified
    Understand Plug and build a simple website using Elixir
    """
  end

  defp package do
    [
      contributors: "LugaTeX",
      liscences: "MIT",
      links: %{"Github" => "https://github.com/kapranov/bitcoin/loss_tracker"}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.18.3", only: :dev, runtime: false},
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1.4", only: :test}
    ]
  end
end
