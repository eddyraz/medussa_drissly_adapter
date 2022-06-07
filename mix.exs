defmodule MedusaDrisslyAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :medusa_drissly_adapter,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MedusaDrisslyAdapter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [

      {:tesla, "~> 1.4"},
      # optional, but recommended adapter
      {:hackney, "~> 1.17"},


      # optional, required by JSON middleware
      {:jason, ">= 1.0.0"},
      {:jaxon, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.7"}


    ]
  end
end
