defmodule Prompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :prompt,
      description: "A terminal toolkit and a set of helpers for building console applications.",
      version: "0.10.1-rc3",
      elixir: "~> 1.12",
      package: package(),
      aliases: aliases(),
      source_url: "https://codeberg.org/ahappydeath/prompt",
      dialyzer: [
        flags: ["-Wunmatched_returns", :error_handling, :underspecs]
      ],
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :iex]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.34.2", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:nimble_options, "~> 1.1.1"}
    ]
  end

  defp package do
    [
      licenses: ["GPL-3.0-or-later"],
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "COPYING*"],
      maintainers: ["Matt Silbernagel"],
      links: %{:SourceHut => "https://git.sr.ht/~ahappydeath/prompt"}
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
      groups_for_docs: [
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

  defp aliases do
    [
      graph: "xref graph --label compile-connected"
    ]
  end
end
