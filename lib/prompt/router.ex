defmodule Prompt.Router do
  @moduledoc """
  Router for Prompt

  Simplifies defining commands, sub-commands and arguments.

  Choose the module responsible for taking the command line arguments and 
  `use Prompt.Router, otp_app: :your_app` at the top.

  Then simply define your commands and arguments.

  Exposes a `main/1` function that is called with the command line args. It
  runs the matching command and halts the VM with the command's exit code.

  Exposes a `run/1` function that does the same but returns the exit code
  instead of halting, which is what you want in tests:

  ```elixir
  assert My.CLI.run(["checkout", "--branch", "dev"]) == 0
  ```

  To have `main/1` return the exit code too, for example when it is called
  from a release or a Mix task, use `use Prompt.Router, otp_app: :my_app, halt: false`.

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
      # If someone called this with `--info --test something`, then
      # arguments will look like `%{info: true, leftover: ["something", "--test"]}`:
      # unused positional values first, then unknown flags as typed
      display("showing info")
    end
  end
  ```

  """

  alias Prompt.Router.{ArgSpec, CommandSpec, Parser}

  @doc """
  The entry point for an escript or release. Calls `c:run/1` with the command
  line args and then halts the VM with the returned exit code.

  If the router was defined with `use Prompt.Router, halt: false`, it returns
  the exit code instead of halting.
  """
  @callback main([binary()]) :: no_return() | non_neg_integer()

  @doc """
  Filters and calls the correct command module based on command line input and
  returns the exit code (see `c:handle_exit_value/1`). It never halts the VM,
  which makes it the function to call from tests.
  """
  @callback run([binary()]) :: non_neg_integer()

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
  This function is called after a command is done.

  It does it's best to handle any value returned from a command and turn 
  it into an integer, 0 being a successful command and any non-zero being
  an error. It returns the code and does not halt, `c:main/1` does that.

  An `{:error, reason}` prints the reason to stderr and results in 1.

  Overrideable
  """
  @callback handle_exit_value(any()) :: non_neg_integer()

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
    halt? = Keyword.get(opts, :halt, true)
    help_text = Keyword.get(opts, :help)

    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote location: :keep do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
      import Prompt, only: [display: 1, display: 2]

      Module.register_attribute(__MODULE__, :commands, accumulate: true, persist: true)

      @behaviour Prompt.Router

      @app unquote(app)
      @prompt_help unquote(help_text)

      @doc false
      def __commands__ do
        __MODULE__.module_info()
        |> Keyword.get(:attributes, [])
        |> Keyword.get_values(:commands)
        |> List.flatten()
        |> Enum.reverse()
      end

      @impl true
      def main(args) do
        code = run(args)

        if unquote(halt?) do
          System.halt(code)
        else
          code
        end
      end

      @impl true
      def run(args) do
        commands =
          __commands__()

        if commands == [] do
          raise "Please define some commands"
        end

        case Prompt.Router.process(args, commands) do
          # C3 replaces the router help below with per-command usage from the spec
          {:help, _spec} ->
            handle_exit_value(help())

          {:error, reason, _spec} ->
            handle_exit_value(help(reason))

          :version ->
            handle_exit_value(version())

          {:completion, shell} ->
            handle_exit_value(generate_completions(shell))

          {:ok, mod, data} ->
            transformed = mod.init(data)
            result = mod.process(transformed)
            handle_exit_value(result)
        end
      end

      @impl true
      def help do
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

        display(reason, color: :red, device: :stderr)
        display(help)
        1
      end

      @impl true
      def version do
        {:ok, vsn} = :application.get_key(@app, :vsn)
        display(List.to_string(vsn))
        0
      end

      @impl true
      def handle_exit_value(:ok), do: handle_exit_value(0)

      def handle_exit_value({:error, reason}) when is_binary(reason) do
        display(reason, color: :red, device: :stderr)
        1
      end

      def handle_exit_value({:error, reason}) do
        display(inspect(reason), color: :red, device: :stderr)
        1
      end

      def handle_exit_value(val) when is_integer(val) and val >= 0, do: val

      def handle_exit_value(_anything_else), do: 2

      def generate_completions("zsh") do
        commands =
          __commands__()

        args =
          for command <- commands, into: "" do
            "#{command.name}\u005c:'' "
          end

        line = "\"1: :((#{args}))\" \\"

        cases =
          for command <- commands, command.name != "", into: "" do
            ~s"""
            \t#{command.name})
            \t\t_#{@app}_#{command.name}
            \t;;
            """
          end

        funcs =
          for command <- commands, command.name != "", into: "" do
            ~s"""
            function _#{@app}_#{command.name} {
            \t_arguments \\
            \t\t#{for arg <- command.args, into: "" do
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
  @spec process([String.t()], [CommandSpec.t()]) :: Parser.result()
  def process(argv, commands), do: Parser.parse(argv, commands)

  @doc """
  Name of the subcommand that is expectedaany()

  Takes an atom or string as the command name and a Prompt.Command module.
  """
  defmacro command(name, module, do: block) do
    args =
      case block do
        {:__block__, _, arguments} -> arguments
        {kind, _, _} = single when kind in [:arg, :positional] -> [single]
      end

    quote do
      Module.put_attribute(
        __MODULE__,
        :commands,
        Prompt.Router.build_command!(unquote(name), unquote(module), unquote(args))
      )
    end
  end

  defmacro command(name, module) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :commands,
        Prompt.Router.build_command!(unquote(name), unquote(module), [])
      )
    end
  end

  @doc false
  def build_command!(name, module, args) do
    positionals = Enum.filter(args, &(&1.kind == :positional))

    case Enum.find_index(positionals, & &1.multiple) do
      nil ->
        :ok

      idx when idx == length(positionals) - 1 ->
        :ok

      _ ->
        raise ArgumentError,
              "command #{inspect(name)}: a positional with multiple: true must be the last positional"
    end

    %Prompt.Router.CommandSpec{name: name, module: module, args: args}
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
    * required - the flag must be given
    * in      - a list of allowed values
    * doc     - a description used in help

  An unknown option raises at compile time.
  """
  defmacro arg(arg_name, arg_type, opts \\ []) do
    quote do
      ArgSpec.new!(unquote(arg_name), unquote(arg_type), :flag, unquote(opts))
    end
  end

  @doc """
  Declares a positional argument of a command.

  ## Options
    * required - the argument must be given
    * multiple - collects all remaining values, only allowed on the last positional
    * in       - a list of allowed values
    * doc      - a description used in help
  """
  defmacro positional(arg_name, arg_type, opts \\ []) do
    quote do
      ArgSpec.new!(unquote(arg_name), unquote(arg_type), :positional, unquote(opts))
    end
  end
end
