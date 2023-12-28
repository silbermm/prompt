defmodule Mix.Tasks.Prompt.Completion do
  @moduledoc """
  Generates CLI completions for the requested shell type (zsh or bash)
  """

  @shortdoc "Generates completions"

  use Mix.Task

  def run(args) do
      
    Mix.shell().info(Enum.join(args, " "))
  end




end

