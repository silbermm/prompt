defmodule Prompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :prompt,
      description: "Build interactive CLI's",
      version: "0.1.0",
      elixir: "~> 1.10",
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs]
      ],
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
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:stream_data, "~> 0.5.0", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      licenses: ["3-Clause BSD License"],
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Matt Silbernagel"],
      links: %{:GitHub => "https://github.com/silbermm/prompt"}
    ]
  end
end
