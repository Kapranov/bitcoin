defmodule LossTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :loss_tracker,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LossTracker.Application, []}
    ]
  end

  defp deps do
    []
  end
end
