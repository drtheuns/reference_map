defmodule ReferenceMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :reference_map,
      version: "0.2.1",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:elixir_uuid, "~> 1.2", only: [:test]},
      {:plug, "~> 1.7"}
    ]
  end
end
