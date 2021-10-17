defmodule Prompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :prompt,
      description: "A terminal toolkit and a set of helpers for building console applications.",
      version: "0.6.0",
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
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
      main: "Prompt",
      extras: ["README.md"],
      logo: "assets/prompt.png"
    ]
  end
end
