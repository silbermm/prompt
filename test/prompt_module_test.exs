defmodule FallbackCommand do
  use Prompt.Command

  @impl true
  def init(_argv) do
    %{}
  end

  @impl true
  def process(_) do
    display("fallback command")
  end
end

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
    process(argv, [test: ExampleCommand], fallback: FallbackCommand)
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
           end) =~ "help"
  end

  test "subcommand" do
    assert capture_io(fn ->
             Example.main(["test"])
           end) =~ "test command"
  end

  test "fallback" do
    assert capture_io(fn ->
             Example.main(["whatever"])
           end) =~ "fallback command"
  end
end
