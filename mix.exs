defmodule Prompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :prompt,
      description: "A terminal toolkit and a set of helpers for building console applications.",
      version: "0.8.0",
      elixir: "~> 1.10",
      package: package(),
      source_url: "https://github.com/silbermm/prompt",
      dialyzer: [
        # plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
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
      {:ex_doc, ">= 0.28.4", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:nimble_options, "~> 0.3.0"}
    ]
  end

  defp package do
    [
      licenses: ["GPL-3.0-or-later"],
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "COPYING*"],
      maintainers: ["Matt Silbernagel"],
      links: %{:GitHub => "https://github.com/silbermm/prompt"}
    ]
  end

  defp docs do
    [
      main: "Prompt",
      api_reference: false,
      extras: [
        "README.md": [filename: "introduction", title: "Introduction"],
        "example.livemd": [filename: "example", title: "Example"],
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"],
        LICENSE: [filename: "license", title: "License"]
      ],
      logo: "assets/prompt.png",
      authors: ["Matt Silbernagel"],
      groups_for_functions: [
        "Input Functions": &(&1[:section] == :input),
        "Output Functions": &(&1[:section] == :output)
      ],
      nest_modules_by_prefix: [
        Prompt,
        Prompt.Command,
        Prompt.Position
      ]
    ]
  end
end
