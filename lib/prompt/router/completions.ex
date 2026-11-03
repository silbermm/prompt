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
defmodule Prompt.Router.Completions do
  @moduledoc false
  # Generates shell completion scripts from command specs. Pure and IO-free:
  # it returns strings and the router prints them.

  alias Prompt.Router.{ArgSpec, CommandSpec}

  @shells ["zsh", "bash", "fish"]

  @doc """
  Generates the completion script for `shell` (`"zsh"`, `"bash"` or `"fish"`).
  Only flags produce `--flag` and `-s` candidates, positionals do not.
  """
  @spec generate(String.t(), atom(), [CommandSpec.t()]) ::
          {:ok, String.t()} | {:error, :unsupported}
  def generate(shell, app, specs) when shell in @shells do
    {:ok, script(shell, app, specs)}
  end

  def generate(_shell, _app, _specs), do: {:error, :unsupported}

  defp script("zsh", app, commands) do
    args =
      for command <- commands, into: "" do
        "#{command.name}\\:'' "
      end

    line = "\"1: :((#{args}))\" \\"

    cases =
      for command <- commands, command.name != "", into: "" do
        ~s"""
        \t#{command.name})
        \t\t_#{app}_#{command.name}
        \t;;
        """
      end

    funcs =
      for command <- commands, command.name != "", into: "" do
        ~s"""
        function _#{app}_#{command.name} {
        \t_arguments \\
        \t\t#{zsh_flags(command)} 
        }

        """
      end

    """
    #compdef #{app}
    local line

    _arguments -C \\
    \t"--help[Show help information]" \\
    \t"--version[Show version information]" \\
    \t"--completion[Generate completion script]:shell_name:->shell_names" \\
    \t#{line} 
    \t"*::arg:->args"

    case "$state" in
    \tshell_names)
    \t\t_values 'shell_names' zsh bash fish
    \t;;
    esac

    case $line[1] in
      #{cases} 
    esac

    #{funcs}
    """
  end

  defp script("bash", app, commands) do
    named = named(commands)
    names = Enum.map_join(named, " ", &to_string(&1.name))
    branches = Enum.map_join(named, "", &bash_branch/1)

    """
    _#{app}() {
    \tlocal cur prev cmd
    \tcur="${COMP_WORDS[COMP_CWORD]}"
    \tprev="${COMP_WORDS[COMP_CWORD-1]}"
    \tcmd="${COMP_WORDS[1]}"

    \tif [ "$prev" = "--completion" ]; then
    \t\tCOMPREPLY=( $(compgen -W "zsh bash fish" -- "$cur") )
    \t\treturn
    \tfi

    \tif [ "$COMP_CWORD" -eq 1 ]; then
    \t\tCOMPREPLY=( $(compgen -W "#{names} --help --version --completion" -- "$cur") )
    \t\treturn
    \tfi

    \tcase "$cmd" in
    #{branches}\tesac
    }

    complete -F _#{app} #{app}
    """
  end

  defp script("fish", app, commands) do
    named = named(commands)

    top = """
    complete -c #{app} -l help -d 'Show help information'
    complete -c #{app} -l version -d 'Show version information'
    complete -c #{app} -l completion -x -a 'zsh bash fish' -d 'Generate completion script'
    """

    names =
      for command <- named, into: "" do
        "complete -c #{app} -n '__fish_use_subcommand' -a #{command.name}\n"
      end

    top <> names <> Enum.map_join(named, "", &fish_command(app, &1))
  end

  defp named(commands), do: Enum.reject(commands, &(to_string(&1.name) == ""))

  # Only flags complete as `--flag`/`-s`; positionals never do.
  defp flags(%CommandSpec{args: args}), do: Enum.filter(args, &(&1.kind == :flag))

  defp choices(%ArgSpec{in: values}) when is_list(values) and values != [],
    do: Enum.join(values, " ")

  defp choices(_arg), do: nil

  defp zsh_flags(command) do
    for arg <- flags(command), into: "" do
      name = ArgSpec.flag_name(arg)
      value = if choices = choices(arg), do: ":#{name}:(#{choices})", else: ""
      long = "\"--#{name}[]#{value}\" "
      if arg.short, do: long <> "\"-#{arg.short}[]#{value}\" ", else: long
    end
  end

  defp switches(arg),
    do: ["--#{ArgSpec.flag_name(arg)}" | if(arg.short, do: ["-#{arg.short}"], else: [])]

  defp bash_branch(command) do
    flags = flags(command)
    words = Enum.flat_map(flags, &switches/1)

    value_cases =
      for arg <- flags, choices = choices(arg), into: "" do
        """
        \t\t\t\t#{Enum.join(switches(arg), "|")})
        \t\t\t\t\tCOMPREPLY=( $(compgen -W "#{choices}" -- "$cur") )
        \t\t\t\t\treturn
        \t\t\t\t\t;;
        """
      end

    value_check =
      if value_cases == "",
        do: "",
        else: "\t\t\tcase \"$prev\" in\n" <> value_cases <> "\t\t\tesac\n"

    "\t\t#{command.name})\n" <>
      value_check <>
      ~s|\t\t\tCOMPREPLY=( $(compgen -W "#{Enum.join(words, " ")}" -- "$cur") )\n| <>
      "\t\t\t;;\n"
  end

  defp fish_command(app, command) do
    condition = "-n '__fish_seen_subcommand_from #{command.name}'"

    for arg <- flags(command), into: "" do
      short = if arg.short, do: " -s #{arg.short}", else: ""
      values = if choices = choices(arg), do: " -xa '#{choices}'", else: ""
      "complete -c #{app} #{condition}#{short} -l #{ArgSpec.flag_name(arg)}#{values}\n"
    end
  end
end
