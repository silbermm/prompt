# Prompt - library to help create interactive CLI in Elixir
# Copyright (C) 2021  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule Prompt.Router.Usage do
  @moduledoc """
  Generates usage text for routers and commands from their specs.

  Inside each section of a command's usage, `Arguments` and `Options` separately,
  every label is padded to the longest label of that section plus 4 spaces.
  """

  alias Prompt.Router.{ArgSpec, CommandSpec}

  @pad 4

  @doc """
  Usage text for one command. `path` is the list of command words typed after
  the app name, for example `["import"]`; the fallback command passes `[]`.
  """
  @spec command(atom() | nil, [String.t()], CommandSpec.t()) :: String.t()
  def command(app, path, %CommandSpec{args: args}) do
    positionals = Enum.filter(args, &(&1.kind == :positional))
    flags = Enum.filter(args, &(&1.kind == :flag))

    words =
      [app_name(app)] ++
        path ++ Enum.map(positionals, &positional_notation/1) ++ options_word(flags)

    usage_line = "Usage: " <> Enum.join(words, " ")

    sections =
      Enum.reject(
        [
          section("Arguments", Enum.map(positionals, &{to_string(&1.name), description(&1)})),
          section("Options", Enum.map(flags, &{flag_label(&1), description(&1)}))
        ],
        &is_nil/1
      )

    Enum.join([usage_line | sections], "\n\n") <> "\n"
  end

  @doc """
  Usage text for a router: its commands with the first line of each command
  module's moduledoc, when docs are available.
  """
  @spec router(atom() | nil, [CommandSpec.t()]) :: String.t()
  def router(app, specs) do
    rows =
      for %CommandSpec{name: name, module: module} <- specs, to_string(name) != "" do
        {to_string(name), first_line(moduledoc(module))}
      end

    usage_line = "Usage: #{app_name(app)} <command> [options]"

    case section("Commands", rows) do
      nil -> usage_line <> "\n"
      commands -> usage_line <> "\n\n" <> commands <> "\n"
    end
  end

  @doc false
  @spec router_help(module(), atom() | nil, String.t() | nil, [CommandSpec.t()]) :: String.t()
  def router_help(module, app, help, specs) do
    cond do
      is_binary(help) -> help
      doc = moduledoc(module) -> doc
      true -> router(app, specs)
    end
  end

  @doc false
  @spec command_help(module() | nil, atom() | nil, [String.t()], CommandSpec.t()) :: String.t()
  def command_help(module, app, path, spec) do
    usage = command(app, path, spec)

    case moduledoc(module) do
      nil -> usage
      doc -> String.trim_trailing(doc) <> "\n\n" <> usage
    end
  end

  @doc """
  The `@moduledoc` text of `module`, or `nil` when docs are not available.
  """
  @spec moduledoc(module() | nil) :: String.t() | nil
  def moduledoc(nil), do: nil

  def moduledoc(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} -> doc
      _ -> nil
    end
  end

  defp app_name(nil), do: "app"
  defp app_name(app), do: to_string(app)

  defp options_word([]), do: []
  defp options_word(_flags), do: ["[options]"]

  defp positional_notation(%ArgSpec{name: name, multiple: multiple, required: required}) do
    base = "<#{name}>" <> if(multiple, do: "...", else: "")
    if required, do: base, else: "[" <> base <> "]"
  end

  defp flag_label(%ArgSpec{name: name, short: nil}), do: "--#{name}"
  defp flag_label(%ArgSpec{name: name, short: short}), do: "-#{short}, --#{name}"

  defp description(%ArgSpec{} = arg) do
    [
      arg.doc,
      arg.in && "(one of: #{Enum.map_join(arg.in, ", ", &to_string/1)})",
      arg.kind == :flag && arg.default != nil && "(default: #{arg.default})",
      arg.required && "(required)"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  defp section(_title, []), do: nil

  defp section(title, rows) do
    width = rows |> Enum.map(fn {label, _} -> String.length(label) end) |> Enum.max()

    lines =
      for {label, desc} <- rows do
        String.trim_trailing("  " <> String.pad_trailing(label, width + @pad) <> desc)
      end

    Enum.join(["#{title}:" | lines], "\n")
  end

  defp first_line(nil), do: ""

  defp first_line(doc) do
    doc |> String.split("\n", trim: true) |> List.first("") |> String.trim()
  end
end
