# Prompt - library to help create interative CLI in Elixir
# Copyright (C) 2020  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
defmodule Prompt.Command do
  @moduledoc """
  Helps users define and build command line commands.

  Defines the behaviour for a Command.

  We expect `init/1` to be called with the command line options and get
  back a data structure that is passed to `process/1` which handles all
  of the side effects of the command itself.

  ## Example
  ```
  defmodule MyCommand do
    @moduledoc "MyCommand's help message help() is defined in the __using__ macro that prints this message if called"

    use Prompt.Command

    @impl true
    def init(_argv) do
      # parse list of args to map or struct
      %{list: true, help: false, directory: "path/to/dir"}
    end

    @impl true
    def process(%{help: true}), do: help() # this help function is defined by default in the macro that prints the @moduledoc when called
    def process(%{list: true, help: false, directory: dir}) do
      display(File.ls!(dir))
    end

  end
  ```

  Typically one will use the `OptionParser.parse/1` function to parse
  the command

  ```
  defp parse(argv) do
   argv
   |> OptionParser.parse(
    strict: [help: :boolean, directory: :string, list: :boolean],
    aliases: [h: :help, d: :directory]
   )
   |> _parse()
  end

  defp _parse({opts, _, _}) do
   help = Keyword.get(opts, :help, false)
   dir = Keyword.get(opts, :directory, "./")
   list = Keyword.get(opts, :length, true)
   %{help: help, directory: dir, list: list}
  end
  ```

  If this is used in a release, `help()` won't print the @moduledoc correctly because releases strip documentation by default. For this to work correctly, tell the release to keep docs:
  ```
  releases: [
    appname: [
      strip_beams: [keep: ["Docs"]]
    ]
  ]
  ```

  """

  @doc """
  Takes the options passed in via the command line and
  tramforms them into a struct that the process command can handle
  """
  @callback init(list(String.t())) :: term

  @doc """
  Prints the help available for this command
  """
  @callback help() :: :ok

  @doc """
  Processes the command and does the things required
  """
  @callback process(term) :: :ok | {:error, binary()}
  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Prompt.Command
      import Prompt

      @doc false
      @impl Prompt.Command
      def help() do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
            _ -> "Help not available"
          end

        display(help)
      end

      defoverridable help: 0

      @doc false
      @impl Prompt.Command
      def init(init_arg) do
        init_arg
      end

      defoverridable init: 1

      @before_compile Prompt.Command
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:process, 1}) do
      message = """
      function process/1 required by behaviour Prompt.Command is not implemented \
      (in module #{inspect(env.module)}).

      You'll need to create the function that takes a list of input and preforms the appropriate actions.
      """

      IO.warn(message, Macro.Env.stacktrace(env))
    end
  end
end
