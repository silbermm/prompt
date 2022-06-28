defmodule Prompt.Router do
  @moduledoc """
  Router for Prompt

  Simplifies defining commands, sub-commands and arguments.

  Choose the module responsible for taking the command line arguments and 
  `use Prompt.Router, otp_app: :your_app` at the top.

  Then simply define your commands and arguments.

  Exposes a main/1 function that is called with the command line args

  ## Example

  ```elixir
  defmodule My.CLI do
    use Prompt.Router, otp_app: :my_app

    command :checkout, My.CheckoutCommand do
      arg :help, :boolean
      arg :branch, :string, default: "main"
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
  @callback main([binary()]) :: non_neg_integer()

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
            help()

          {:help, reason} ->
            help(reason)

          :version ->
            version()

          {mod, data} ->
            transformed = apply(mod, :init, [data])
            apply(mod, :process, [transformed])
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

      defoverridable help: 0
      defoverridable help: 1
      defoverridable version: 0
    end
  end

  @doc false
  def process(argv, commands) do
    # first figure out which command was passed in
    argv
    |> OptionParser.parse_head(
      switches: [help: :boolean, version: :boolean],
      aliases: [h: :help, v: :version]
    )
    |> parse_opts(commands, argv)
  end

  # if help or version were passed, process them and exit
  defp parse_opts({[help: true], _, _}, _, _), do: :help
  defp parse_opts({[version: true], _, _}, _, _), do: :version

  defp parse_opts({_, additional, _}, defined_commands, original) do
    case additional do
      [head | rest] ->
        # if there is an array of data, then a subcommand was passed in
        command = find_in_defined_commands(defined_commands, head)

        if command == nil do
          # try fallback option
          fallback_command(original, defined_commands)
        else
          # process the options for the module
          switches = build_parser_switches(command)
          {parsed, leftover, _} = OptionParser.parse_head(rest, switches: switches)
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
  defp build_parser_switches(command), do: Enum.map(command.arguments, &{&1.name, &1.type})

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

  defmacro arg(arg_name, arg_type, opts \\ []) do
    quote do
      %{name: unquote(arg_name), type: unquote(arg_type), options: unquote(opts)}
    end
  end
end
