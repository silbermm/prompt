defmodule Mix.Tasks.Prompt.Completion do
  @moduledoc """
  Generates CLI completions for the requested shell type (zsh or bash)
  """

  @shortdoc "Generates completions"

  use Mix.Task
  import Prompt

  def run(args) do
    # Mix.shell().info(Enum.join(args, " "))
    case OptionParser.parse(args, strict: [debug: :boolean]) do
      {_, [module_name], _} ->
        handle_module(module_name)
      _ -> display("""
      Usage: mix prompt.comletion MyCliModule

      Where MyCliModule implements Prompt.Router
      """)
    end
  end

  defp handle_module(module_name) do
    module = String.to_atom("Elixir.#{module_name}")
    dbg apply(module, :__info__, [])
  end
end
