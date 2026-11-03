defmodule Prompt.Router.SpecTest do
  use ExUnit.Case, async: true

  alias Prompt.Router.{ArgSpec, CommandSpec}

  defmodule SomeCommand do
    use Prompt.Command

    @impl true
    def init(argv), do: argv

    @impl true
    def process(_), do: :ok
  end

  defmodule SpecTestRouter do
    use Prompt.Router, otp_app: :prompt, help: "custom help"

    command :import, SomeCommand do
      arg(:dry_run, :boolean, short: :d, doc: "do nothing")
      positional(:files, :string, multiple: true)
    end
  end

  test "arg builds a flag spec" do
    assert %ArgSpec{name: :group, kind: :flag, required: true, in: ["a", "b"]} =
             ArgSpec.new!(:group, :string, :flag, required: true, in: ["a", "b"])
  end

  test "unknown arg option raises" do
    assert_raise ArgumentError, ~r/unknown options \[:requird\]/, fn ->
      ArgSpec.new!(:group, :string, :flag, requird: true)
    end
  end

  test "a router compiles with a positional and the specs are CommandSpec structs" do
    [spec] = SpecTestRouter.__commands__()

    assert %CommandSpec{name: :import, args: [%ArgSpec{kind: :flag, short: :d}, positional]} =
             spec

    assert %ArgSpec{kind: :positional, multiple: true} = positional
    assert spec.subcommands == []
  end

  test "a multiple positional that is not last fails compilation" do
    assert_raise ArgumentError, ~r/multiple/, fn ->
      Code.compile_string("""
      defmodule Prompt.Router.SpecTest.BadRouter do
        use Prompt.Router, otp_app: :prompt

        command :bad, Prompt.Router.SpecTest.SomeCommand do
          positional :files, :string, multiple: true
          positional :dest, :string
        end
      end
      """)
    end
  end
end
