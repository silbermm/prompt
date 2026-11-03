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

defmodule ErrorCommand do
  use Prompt.Command

  @impl true
  def init(_argv), do: %{}

  @impl true
  def process(_), do: {:error, "disk full"}
end

defmodule Example do
  use Prompt.Router, otp_app: :prompt

  command(:fail, ErrorCommand)

  command :test, ExampleCommand do
    arg(:help, :boolean)
  end

  command "", FallbackCommand do
    arg(:help, :boolean)
  end

  @impl true
  def help do
    display("help")
  end
end

defmodule ExampleNoHalt do
  use Prompt.Router, otp_app: :prompt, halt: false

  command(:test, ExampleCommand)
end

defmodule PromptModuleTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    Application.put_env(:prompt, :io, IO)
  end

  test "show help" do
    assert capture_io(fn ->
             Example.run(["--help"])
           end) =~ "help"
  end

  test "subcommand" do
    assert capture_io(fn ->
             Example.run(["test"])
           end) =~ "test command"
  end

  test "unknown command forwards to the fallback command" do
    assert capture_io(fn ->
             Example.run(["whatever"])
           end) =~ "[39mfallback command"
  end

  test "fallback" do
    assert capture_io(fn ->
             Example.run([])
           end) =~ "fallback command"
  end

  test "run returns 0 for a command that returns :ok" do
    capture_io(fn -> assert Example.run(["test"]) == 0 end)
  end

  test "run returns 1 and prints the reason to stderr for {:error, reason}" do
    stderr = capture_io(:stderr, fn -> assert Example.run(["fail"]) == 1 end)
    assert stderr =~ "disk full"
  end

  test "run returns 0 for --help and --version" do
    capture_io(fn -> assert Example.run(["--help"]) == 0 end)
    capture_io(fn -> assert Example.run(["--version"]) == 0 end)
  end

  test "main returns the code instead of halting when halt: false" do
    capture_io(fn -> assert ExampleNoHalt.main(["test"]) == 0 end)
  end
end
