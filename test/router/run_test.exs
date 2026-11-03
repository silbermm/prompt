defmodule Prompt.Router.RunTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  defmodule NeedsText do
    use Prompt.Command

    @impl true
    def init(args), do: args

    @impl true
    def process(%{text: text}), do: display("searching " <> text)
  end

  defmodule RunRouter do
    use Prompt.Router, otp_app: :prompt

    command :search, NeedsText do
      positional(:text, :string, required: true)
    end
  end

  setup do
    old = Application.get_env(:prompt, :io)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
  end

  test "an error prints the reason to stderr, not stdout, and returns 1" do
    # Nesting capture_io(:stderr) around a :stdio display crashes user_drv
    # without a TTY, so record writes through the mock instead.
    Application.put_env(:prompt, :io, Prompt.IO.Mock)
    test_pid = self()

    Mox.stub(Prompt.IO.Mock, :write, fn device, io ->
      send(test_pid, {:write, device, IO.iodata_to_binary(io)})
      :ok
    end)

    assert RunRouter.run(["search"]) == 1
    writes = collect_writes([])
    stderr = for {:stderr, out} <- writes, into: "", do: out
    stdout = for {:stdio, out} <- writes, into: "", do: out
    assert stderr =~ "missing required argument text"
    refute stdout =~ "missing required argument"
  end

  defp collect_writes(acc) do
    receive do
      {:write, device, out} -> collect_writes([{device, out} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  test "command --help returns 0" do
    Application.put_env(:prompt, :io, IO)
    capture_io(fn -> assert RunRouter.run(["search", "--help"]) == 0 end)
  end

  test "a valid command runs" do
    Application.put_env(:prompt, :io, IO)

    assert capture_io(fn -> assert RunRouter.run(["search", "milk"]) == 0 end) =~
             "searching milk"
  end
end
