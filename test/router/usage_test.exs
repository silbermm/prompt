defmodule Prompt.Router.UsageTest do
  use ExUnit.Case, async: false

  alias Prompt.Router.{ArgSpec, CommandSpec, Usage}

  # Docs are only available for compiled modules, so use real lib modules.
  @documented Prompt.Command
  @no_docs Prompt.Router.Parser

  defp spec do
    %CommandSpec{
      name: :import,
      module: @documented,
      args: [
        ArgSpec.new!(:account, :string, :positional,
          required: true,
          doc: "Account to import into"
        ),
        ArgSpec.new!(:files, :string, :positional,
          required: true,
          multiple: true,
          doc: "CSV files"
        ),
        ArgSpec.new!(:format, :string, :flag,
          short: :f,
          in: ["csv", "ofx"],
          default: "csv",
          doc: "Input format"
        ),
        ArgSpec.new!(:"dry-run", :boolean, :flag, doc: "Show what would be imported")
      ]
    }
  end

  test "command usage pads each section to its longest label plus 4" do
    assert Usage.command(:fin, ["import"], spec()) == """
           Usage: fin import <account> <files>... [options]

           Arguments:
             account    Account to import into (required)
             files      CSV files (required)

           Options:
             -f, --format    Input format (one of: csv, ofx) (default: csv)
             --dry-run       Show what would be imported
           """
  end

  test "optional positionals and no flags" do
    spec = %CommandSpec{
      name: :x,
      args: [
        ArgSpec.new!(:a, :string, :positional, []),
        ArgSpec.new!(:b, :string, :positional, multiple: true)
      ]
    }

    assert Usage.command(:fin, ["x"], spec) =~ "Usage: fin x [<a>] [<b>...]\n"
    refute Usage.command(:fin, ["x"], spec) =~ "[options]"
  end

  test "required flag and fallback path" do
    spec = %CommandSpec{name: "", args: [ArgSpec.new!(:n, :string, :flag, required: true)]}

    assert Usage.command(:fin, [], spec) == """
           Usage: fin [options]

           Options:
             --n    (required)
           """
  end

  test "router usage lists commands with first moduledoc line" do
    specs = [
      %CommandSpec{name: :import, module: @documented},
      %CommandSpec{name: :bare, module: @no_docs},
      %CommandSpec{name: "", module: @no_docs}
    ]

    assert Usage.router(:fin, specs) == """
           Usage: fin <command> [options]

           Commands:
             import    Helps users define and build command line commands.
             bare
           """
  end

  test "router with help: prints it from help/0" do
    import ExUnit.CaptureIO
    old = Application.get_env(:prompt, :io)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
    Application.put_env(:prompt, :io, IO)

    defmodule CustomHelp do
      use Prompt.Router, otp_app: :prompt, help: "custom"
      command(:a, Prompt.Router.Parser)
    end

    assert capture_io(fn -> assert CustomHelp.help() == 0 end) =~ "custom"
  end

  test "a router without help: falls back to generated usage, never 'Help not available'" do
    import ExUnit.CaptureIO
    old = Application.get_env(:prompt, :io)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
    Application.put_env(:prompt, :io, IO)

    defmodule PlainRouter do
      use Prompt.Router, otp_app: :fin
      command(:import, Prompt.Command)
    end

    out = capture_io(fn -> assert PlainRouter.help() == 0 end)
    assert out =~ "Usage: fin <command> [options]"
    assert out =~ "Helps users define and build command line commands."
    refute out =~ "Help not available"
  end

  defmodule UsageRouter do
    use Prompt.Router, otp_app: :fin

    command :import, Prompt.Command do
      positional(:account, :string, required: true)
      arg(:format, :string, in: ["csv", "ofx"])
    end
  end

  test "command --help prints usage and exits 0" do
    import ExUnit.CaptureIO
    old = Application.get_env(:prompt, :io)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
    Application.put_env(:prompt, :io, IO)

    out = capture_io(fn -> assert UsageRouter.run(["import", "--help"]) == 0 end)
    assert out =~ "Usage: fin import <account> [options]"
    assert out =~ "Helps users define and build command line commands."
  end

  test "a bad value prints the reason to stderr, then the command usage, and exits 1" do
    old = Application.get_env(:prompt, :io)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
    Application.put_env(:prompt, :io, Prompt.IO.Mock)
    test_pid = self()

    Mox.stub(Prompt.IO.Mock, :write, fn device, io ->
      send(test_pid, {:write, device, IO.iodata_to_binary(io)})
      :ok
    end)

    assert UsageRouter.run(["import", "a", "--format", "x"]) == 1
    writes = collect_writes([])
    stderr = for {:stderr, out} <- writes, into: "", do: out
    stdout = for {:stdio, out} <- writes, into: "", do: out
    assert stderr =~ "format"
    assert stderr =~ "csv, ofx"
    assert stdout =~ "Usage: fin import <account> [options]"
    refute stderr =~ "Usage:"
  end

  defp collect_writes(acc) do
    receive do
      {:write, device, out} -> collect_writes([{device, out} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  test "an underscore flag is shown with a dash" do
    spec = %CommandSpec{
      name: :import,
      module: nil,
      args: [ArgSpec.new!(:dry_run, :boolean, :flag, short: :d)]
    }

    out = Usage.command(:fin, ["import"], spec)
    assert out =~ "-d, --dry-run"
    refute out =~ "dry_run"
  end
end
