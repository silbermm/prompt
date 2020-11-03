defmodule Prompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :prompt,
      description: "Build interactive CLI's",
      version: "0.1.7",
      elixir: "~> 1.10",
      package: package(),
      source_url: "https://github.com/silbermm/prompt",
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs]
      ],
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Prompt.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["GPL-3.0-or-later"],
      files: ["lib", "mix.exs", "README.md", "COPYING*"],
      maintainers: ["Matt Silbernagel"],
      links: %{:GitHub => "https://github.com/silbermm/prompt"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
