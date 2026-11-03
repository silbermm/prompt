defmodule Prompt.Router.CompletionsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Prompt.Router.Completions

  defmodule NoopCommand do
    use Prompt.Command

    @impl true
    def init(args), do: args

    @impl true
    def process(_), do: :ok
  end

  defmodule Rich do
    use Prompt.Router, otp_app: :prompt

    command :find, NoopCommand do
      arg(:verbose, :boolean, short: :v)
      arg(:group, :string, short: :g, in: ["a", "b"])
      positional(:files, :string, multiple: true)
    end

    command(:other, NoopCommand)
  end

  setup do
    old = Application.get_env(:prompt, :io)
    Application.put_env(:prompt, :io, IO)
    on_exit(fn -> Application.put_env(:prompt, :io, old) end)
  end

  defp fixture(name), do: File.read!(Path.join("test/fixtures/completions", name))

  test "zsh output for Example matches the snapshot" do
    out = capture_io(fn -> assert Example.generate_completions("zsh") == 0 end)
    assert out == fixture("example.zsh")
  end

  test "bash output for Example matches the fixture" do
    assert {:ok, script} = Completions.generate("bash", :prompt, Example.__commands__())
    assert script == fixture("example.bash")
  end

  test "fish output for Example matches the fixture" do
    assert {:ok, script} = Completions.generate("fish", :prompt, Example.__commands__())
    assert script == fixture("example.fish")
  end

  test "an unknown shell is unsupported" do
    assert Completions.generate("tcsh", :prompt, Rich.__commands__()) == {:error, :unsupported}
  end

  test "run with an unsupported shell returns 1" do
    capture_io(fn -> assert Example.run(["--completion", "tcsh"]) == 1 end)
  end

  test "bash and fish scripts are printed with exit code 0" do
    for shell <- ["bash", "fish"] do
      out = capture_io(fn -> assert Rich.run(["--completion", shell]) == 0 end)
      assert out =~ "find"
    end
  end

  for shell <- ["zsh", "bash", "fish"] do
    test "#{shell}: positionals do not leak as flags, flags and in: values complete" do
      {:ok, script} = Completions.generate(unquote(shell), :prompt, Rich.__commands__())
      refute script =~ "files"
      assert script =~ "verbose"
      assert script =~ "group"
      assert script =~ "a b"
    end
  end

  test "zsh uses the _arguments value syntax for in:" do
    {:ok, script} = Completions.generate("zsh", :prompt, Rich.__commands__())
    assert script =~ "\"--group[]:group:(a b)\""
  end

  test "fish completes in: values after the flag" do
    {:ok, script} = Completions.generate("fish", :prompt, Rich.__commands__())

    assert script =~
             "complete -c prompt -n '__fish_seen_subcommand_from find' -s g -l group -xa 'a b'"
  end

  test "bash registers a compgen based completion function" do
    {:ok, script} = Completions.generate("bash", :prompt, Rich.__commands__())
    assert script =~ "complete -F _prompt prompt"
    assert script =~ "compgen -W"
  end

  test "zsh emits short flags" do
    {:ok, script} = Completions.generate("zsh", :prompt, Rich.__commands__())
    assert script =~ "\"--verbose[]\" \"-v[]\""
    assert script =~ "\"-g[]:group:(a b)\""
  end

  test "bash emits short flags in the word list and the in: case label" do
    {:ok, script} = Completions.generate("bash", :prompt, Rich.__commands__())
    assert script =~ "-W \"--verbose -v --group -g\""
    assert script =~ "--group|-g)"
  end

  test "fish emits short flags" do
    {:ok, script} = Completions.generate("fish", :prompt, Rich.__commands__())
    assert script =~ "-s v -l verbose"
    assert script =~ "-s g -l group"
  end

  defmodule Underscore do
    use Prompt.Router, otp_app: :prompt

    command :sync, NoopCommand do
      arg(:dry_run, :boolean, short: :d)
      arg(:log_level, :string, in: ["info", "debug"])
    end
  end

  for shell <- ["zsh", "bash", "fish"] do
    test "#{shell}: underscore flags complete with a dash" do
      {:ok, script} = Completions.generate(unquote(shell), :prompt, Underscore.__commands__())
      assert script =~ "dry-run"
      assert script =~ "log-level"
      refute script =~ "dry_run"
      refute script =~ "log_level"
    end
  end
end
