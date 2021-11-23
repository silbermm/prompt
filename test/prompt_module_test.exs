defmodule ExampleCommand do
  use Prompt.Command

  @impl true
  def init(_argv) do
    %{}
  end

  @impl true
  def process(_) do
    display("test command")
  end
end

defmodule Example do
  use Prompt, otp_app: :prompt

  def main(argv) do
    process(argv, test: ExampleCommand)
  end

  @impl true
  def help do
    display("help")
  end
end

defmodule PromptModuleTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "show help" do
    assert capture_io(fn ->
             Example.main(["--help"])
           end) == "\e[10000D\e[0m\e[49m\e[39mhelp\e[0m\n\e[0m"
  end

  test "subcommand" do
    assert capture_io(fn ->
             Example.main(["test"])
           end) == "\e[10000D\e[0m\e[49m\e[39mtest command\e[0m\n\e[0m"
  end
end
