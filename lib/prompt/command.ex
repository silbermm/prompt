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
  back a data structure that is passed to `parse/1` which handles all
  of the side effects of the command itself.

  ## Example
  ```
  defmodule MyCommand do
    @moduledoc "MyCommand's help message"

    use Prompt.Command

    @impl true
    def init(args) do
      # parse list of args to map or struct
      %{list: true, help: false, directory: "path/to/dir"}
    end

    @impl true
    def process(%{help: true}), do: help()
    def process(%{list: true, help: false, directory: dir}) do
      display(File.ls!(dir))
    end

    @impl true
    def help(), do: display(@moduledoc)
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
    quote location: :keep do
      @behaviour Prompt.Command
      import Prompt

      @doc false
      def help() do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
          end

        display(help)
      end

      @before_compile Prompt.Command

      defoverridable help: 0
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:init, 1}) do
      message = """
      function init/1 required by behaviour Prompt.Command is not implemented \
      (in module #{inspect(env.module)}).

      You'll need to create the function that takes a list of input and converts
      it to a data struture that is passed to your process/1 function.
      """

      IO.warn(message, Macro.Env.stacktrace(env))

      quote do
        @doc false
        def init(init_arg) do
          init_arg
        end

        defoverridable init: 1
      end
    end
  end
end
