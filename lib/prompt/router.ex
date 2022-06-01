defmodule Prompt.Router do
  @moduledoc """
  Router for Prompt
  """

  @doc """
  Prints help to the screen when there is an error, or `--help` is passed as an argument
  """
  @callback help() :: :non_neg_integer

  @doc """
  Prints help to the screen when there is an error, or `--help` is passed as an argument
  """
  @callback help(atom()) :: :non_neg_integer

  defmacro __using__(opts) do
    app = Keyword.get(opts, :otp_app, nil)

    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
      import Prompt

      @behaviour Prompt.Router

      @app unquote(app)

      @doc """
      Takes the command line arguments as a list
      parses them and calls the correct module with
      the correct options
      """
      def main(args) do
        commands =
          __MODULE__.module_info()
          |> Keyword.get(:attributes, [])
          |> Keyword.get_values(:commands)
          |> List.flatten()

        if commands == [] do
          raise "Please define some commands"
        end

        case process(args, commands) do
          :help ->
            help()
            0

          :version ->
            {:ok, vsn} = :application.get_key(@app, :vsn)
            display(List.to_string(vsn))
            0

          {mod, data} ->
            transformed = apply(mod, :init, [data])
            apply(mod, :process, [transformed])
        end
      end

      defp process(argv, commands) do
        # first figure out which command was passed in
        argv
        |> OptionParser.parse_head(
          switches: [help: :boolean, version: :boolean],
          aliases: [h: :help, v: :version]
        )
        |> parse_opts(commands)
      end

      # if help or version were passed, process them and exit
      defp parse_opts({[help: true], _, _}, _), do: :help
      defp parse_opts({[version: true], _, _}, _), do: :version

      defp parse_opts({[], [head | rest] = all, _} = everything, defined_commands) do
        res =
          Enum.find(defined_commands, fn
            %{command_name: command_name_atom} -> head == to_string(command_name_atom)
            _ -> false
          end)

        case res do
          nil ->
            :help

          _ ->
            # process the options for the module
            switches = Enum.map(res.arguments, &{&1.name, &1.type})
            {parsed, left_over, _} = OptionParser.parse_head(rest, switches: switches)

            data =
              res.arguments
              |> Enum.reduce(%{}, fn arg, acc ->
                Map.put_new(acc, arg.name, Keyword.get(parsed, arg.name, default_value(arg)))
              end)
              |> Map.put_new(:leftover, left_over)

            {res.module, data}
        end
      end

      defp default_value(%{type: type, options: [_ | _] = opts}),
        do: Keyword.get(opts, :default, default_value(%{type: type}))

      defp default_value(%{type: :boolean}), do: false
      defp default_value(%{type: :string}), do: ""
      defp default_value(%{type: :integer}), do: nil
      defp default_value(%{type: :float}), do: nil

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
      end

      @impl true
      def help(_reason) do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
            _ -> "Help not available"
          end

        display(help)
      end
    end
  end

  defmacro commands(do: block) do
    quote do
      Module.register_attribute(__MODULE__, :commands, accumulate: true, persist: true)
      unquote(block)
    end
  end

  defmacro command(name, module, do: block) when is_atom(name) do
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

  defmacro command(_name, _module, do: _block), do: raise("command name must be an atom")

  defmacro arg(arg_name, arg_type, opts \\ []) do
    quote do
      %{name: unquote(arg_name), type: unquote(arg_type), options: unquote(opts)}
    end
  end
end
