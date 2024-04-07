defmodule Prompt.Router do
  @moduledoc """
  Router for Prompt

  Simplifies defining commands, sub-commands and arguments.

  Choose the module responsible for taking the command line arguments and 
  `use Prompt.Router, otp_app: :your_app` at the top.

  Then simply define your commands and arguments.

  Exposes a main/1 function that is called with the command line args

  ## Arguments
  See `arg/3`

  ## Example

  ```elixir
  defmodule My.CLI do
    use Prompt.Router, otp_app: :my_app

    command :checkout, My.CheckoutCommand do
      arg :help, :boolean
      arg :branch, :string, short: :b, default: "main"
    end

    command "", My.DefaultCommand do
      arg :info, :boolean
    end
  end

  defmodule My.CheckoutCommand do
    use Prompt.Command

    @impl true
    def process(arguments) do
      # arguments will be a map of the defined arguments and their values
      # from the command line input
      # If someone used the command and passed `--branch  feature/test`, then
      # `argmuments would look like `%{help: false, branch: "feature/test"}`
      display("checking out " <> arguments.branch)
    end
  end

  defmodule My.DefaultCommand do
    use Prompt.Command

    @impl true
    def init(arguments) do
      # you can implement the `c:init/1` callback to transform
      # the arguments before `c:process/1` is called if you want
      arguments
    end
    
    @impl true
    def process(arguments) do
      # arguments will have a key of `:leftover` for anything
      # passed to the command that doesn't have a `arg` defined.
      # IF someone called this with `--info --test something`, then then
      # arguments will look like `%{info: true, leftover: ["--test", "something"]}`
      display("showing info")
    end
  end
  ```

  """

  @doc """
  The function responsible for filtering and calling the correct command 
  module based on command line input
  """
  @callback main([binary()]) :: no_return()

  @doc """
  Prints help to the screen when there is an error, or `--help` is passed as an argument. 

  Overridable
  """
  @callback help() :: non_neg_integer()

  @doc """
  Prints help to the screen when there is an error with a string indicating the error

  Overridable
  """
  @callback help(String.t()) :: non_neg_integer()

  @doc """
  Prints the version from the projects mix.exs file

  Overridable
  """
  @callback version() :: non_neg_integer()

  @doc """
  This function is called after the main function is done.

  It does it's best to handle any value returned from a command and turn 
  it into an integer, 0 being a successful command and any non-zero being
  an error.

  Overrideable
  """
  @callback handle_exit_value(any()) :: no_return()

  @doc """
  Called when the flag `--completions string` is passed on the command-line.

  The default behaviour for this is to write the completion script to the
  screen.

  zsh is supported out of the box. If other completion scripts are required,
  this callback will need to be implemented.

  see https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org

  Overrideable
  """
  @callback generate_completions(binary()) :: non_neg_integer()

  defmacro __using__(opts) do
    app = Keyword.get(opts, :otp_app, nil)

    quote location: :keep do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
      import Prompt, only: [display: 1, display: 2]

      Module.register_attribute(__MODULE__, :commands, accumulate: true, persist: true)

      @behaviour Prompt.Router

      @app unquote(app)

      @impl true
      def main(args) do
        commands =
          __MODULE__.module_info()
          |> Keyword.get(:attributes, [])
          |> Keyword.get_values(:commands)
          |> List.flatten()

        if commands == [] do
          raise "Please define some commands"
        end

        case Prompt.Router.process(args, commands) do
          :help ->
            handle_exit_value(help())

          {:help, reason} ->
            handle_exit_value(help(reason))

          :version ->
            handle_exit_value(version())

          {:completion, shell} ->
            generate_completions(shell)

          {mod, data} ->
            transformed = apply(mod, :init, [data])
            result = apply(mod, :process, [transformed])
            handle_exit_value(result)
        end
      end

      @impl true
      def help() do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
            _ -> "Help not available"
          end

        display(help)
        0
      end

      @impl true
      def help(reason) do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
            _ -> "Help not available"
          end

        display(reason, color: :red)
        display(help)
        1
      end

      @impl true
      def version() do
        {:ok, vsn} = :application.get_key(@app, :vsn)
        display(List.to_string(vsn))
        0
      end

      @impl true
      def handle_exit_value(:ok), do: handle_exit_value(0)

      def handle_exit_value({:error, _reason}) do
        handle_exit_value(1)
      end

      def handle_exit_value(val) when is_integer(val) and val >= 0 do
        # Prevent exiting if running from an iex console.
        unless Code.ensure_loaded?(IEx) and IEx.started?() do
          System.halt(val)
        end
      end

      def handle_exit_value(anything_else) do
        handle_exit_value(2)
      end

      def generate_completions("zsh") do
        commands =
          __MODULE__.module_info()
          |> Keyword.get(:attributes, [])
          |> Keyword.get_values(:commands)
          |> List.flatten()

        args =
          for command <- commands, into: "" do
            "#{command.command_name}\u005c:'' "
          end

        line = "\"1: :((#{args}))\" \\"

        cases =
          for command <- commands, command.command_name != "", into: "" do
            ~s"""
            \t#{command.command_name})
            \t\t_#{@app}_#{command.command_name}
            \t;;
            """
          end

        funcs =
          for command <- commands, command.command_name != "", into: "" do
            ~s"""
            function _#{@app}_#{command.command_name} {
            \t_arguments \\
            \t\t#{for arg <- command.arguments, into: "" do
              "\"--#{arg.name}[]\" "
            end} 
            }

            """
          end

        base = """
        #compdef #{@app}
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

        display(base)
        0
      end

      @impl true
      def generate_completions(shell) do
        display("Completions for #{shell} are not supported", color: :yellow)
        1
      end

      defoverridable help: 0
      defoverridable help: 1
      defoverridable version: 0
      defoverridable handle_exit_value: 1
      defoverridable generate_completions: 1
    end
  end

  @doc false
  def process(argv, commands) do
    # first figure out which command was passed in
    argv
    |> OptionParser.parse_head(
      switches: [help: :boolean, version: :boolean, completion: :string],
      aliases: [h: :help, v: :version]
    )
    |> parse_opts(commands, argv)
  end

  # if help or version were passed, process them and exit
  defp parse_opts({[help: true], _, _}, _, _), do: :help
  defp parse_opts({[version: true], _, _}, _, _), do: :version
  defp parse_opts({[completion: shell], _, _}, _, _), do: {:completion, shell}

  defp parse_opts({_, additional, _}, defined_commands, original) do
    case additional do
      [head | rest] ->
        # if there is an array of data, then a subcommand was passed in
        command = find_in_defined_commands(defined_commands, head)

        if command == nil do
          # the passed in command or option is not recognized, try the fallback
          # passing the data as options
          fallback_command(original, defined_commands)
        else
          # process the options for the module
          switches = build_parser_switches(command)
          aliases = build_parser_aliases(command)

          {parsed, leftover, _} =
            OptionParser.parse_head(rest, switches: switches, aliases: aliases)

          data = build_command_data(command, parsed, leftover)
          {command.module, data}
        end

      [] ->
        # no subcommand was passed in try the fallback module
        fallback_command(original, defined_commands)
    end
  end

  defp fallback_command(original_args, defined_commands) do
    # no subcommand was passed in try the fallback module
    fallback = find_in_defined_commands(defined_commands, "")

    if fallback == nil do
      {:help, "invalid flag or command"}
    else
      switches = build_parser_switches(fallback)
      {parsed, leftover, _} = OptionParser.parse(original_args, switches: switches)
      data = build_command_data(fallback, parsed, leftover)
      {fallback.module, data}
    end
  end

  defp find_in_defined_commands(defined_commands, "") do
    Enum.find(defined_commands, fn
      %{command_name: ""} -> true
      _ -> false
    end)
  end

  defp find_in_defined_commands(defined_commands, command_value) do
    Enum.find(defined_commands, fn
      %{command_name: command_name_atom} -> command_value == to_string(command_name_atom)
      _ -> false
    end)
  end

  defp build_parser_switches(nil), do: []

  defp build_parser_switches(command) do
    Enum.map(command.arguments, &{&1.name, &1.type})
  end

  defp build_parser_aliases(nil), do: []

  defp build_parser_aliases(command) do
    for args <- command.arguments, reduce: [] do
      a ->
        if Keyword.has_key?(args.options, :short) do
          [{Keyword.get(args.options, :short), args.name} | a]
        else
          a
        end
    end
  end

  defp build_command_data(command, parsed, leftover) do
    command.arguments
    |> Enum.reduce(%{}, fn arg, acc ->
      Map.put_new(acc, arg.name, Keyword.get(parsed, arg.name, default_value(arg)))
    end)
    |> Map.put_new(:leftover, leftover)
  end

  defp default_value(%{type: type, options: [_ | _] = opts}),
    do: Keyword.get(opts, :default, default_value(%{type: type}))

  defp default_value(%{type: :boolean}), do: false
  defp default_value(%{type: :string}), do: ""
  defp default_value(%{type: :integer}), do: nil
  defp default_value(%{type: :float}), do: nil

  @doc """
  Name of the subcommand that is expectedaany()

  Takes an atom or string as the command name and a Prompt.Command module.
  """
  defmacro command(name, module, do: block) do
    args =
      case block do
        {:__block__, _, arguments} -> arguments
        {:arg, _, _} = args -> [args]
      end

    quote do
      new_args = Enum.map(unquote(args), fn o -> o end)

      res = %{
        command_name: unquote(name),
        module: unquote(module),
        arguments: new_args
      }

      Module.put_attribute(__MODULE__, :commands, res)
    end
  end

  defmacro command(name, module) do
    quote do
      res = %{
        command_name: unquote(name),
        module: unquote(module),
        arguments: []
      }

      Module.put_attribute(__MODULE__, :commands, res)
    end
  end

  @doc """
  Defines the arguments of a command.
  ## Argument Name
  This indicates what the user will type as the option to the sub-command.
  For example,
  ```elixir
  arg :print, :boolean
  ```
  would allow the user to type `$ your_command --print`

  ## Options
  Available options are:
    * default - a default value if the user doesn't use this option
    * short   - an optional short argument option i.e `short: :h` would all the user to type `-h`
  """
  defmacro arg(arg_name, arg_type, opts \\ []) do
    quote do
      %{name: unquote(arg_name), type: unquote(arg_type), options: unquote(opts)}
    end
  end
end
