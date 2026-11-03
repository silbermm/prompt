defmodule Prompt.Router.ParserTest do
  use ExUnit.Case, async: true

  alias Prompt.Router.{ArgSpec, CommandSpec, Parser}

  defp spec(name, args, module \\ __MODULE__) do
    %CommandSpec{name: name, module: module, args: args}
  end

  defp flag(name, type, opts \\ []), do: ArgSpec.new!(name, type, :flag, opts)
  defp pos(name, type, opts \\ []), do: ArgSpec.new!(name, type, :positional, opts)

  describe "positionals" do
    test "a multiple positional collects every value" do
      import_spec = spec(:import, [pos(:files, :string, multiple: true)])

      assert {:ok, __MODULE__, %{files: ["a.csv", "b.csv"], leftover: []}} ==
               Parser.parse(["import", "a.csv", "b.csv"], [import_spec])
    end

    test "flags may follow positionals" do
      search = spec(:search, [pos(:text, :string, required: true), flag(:limit, :integer)])

      assert {:ok, __MODULE__, %{text: "kroger", limit: 5, leftover: []}} ==
               Parser.parse(["search", "kroger", "--limit", "5"], [search])
    end

    test "positionals do not become switches" do
      import_spec = spec(:import, [pos(:files, :string, multiple: true)])

      assert {:ok, __MODULE__, %{files: [], leftover: ["--files"]}} ==
               Parser.parse(["import", "--files"], [import_spec])
    end

    test "a missing optional positional is nil and an unused value lands in leftover" do
      cmd = spec(:show, [pos(:id, :string)])

      assert {:ok, __MODULE__, %{id: nil, leftover: []}} == Parser.parse(["show"], [cmd])

      assert {:ok, __MODULE__, %{id: "1", leftover: ["2", "--bogus"]}} ==
               Parser.parse(["show", "1", "--bogus", "2"], [cmd])
    end

    test "typed positionals are converted" do
      cmd = spec(:take, [pos(:count, :integer), pos(:ratio, :float)])

      assert {:ok, __MODULE__, %{count: 3, ratio: 0.5, leftover: []}} ==
               Parser.parse(["take", "3", "0.5"], [cmd])
    end

    test "a typed positional that does not convert is an error" do
      cmd = spec(:take, [pos(:count, :integer)])

      assert {:error, ~s(invalid value "abc" for count, expected integer), cmd} ==
               Parser.parse(["take", "abc"], [cmd])
    end
  end

  describe "required" do
    test "a missing required positional is an error" do
      search = spec(:search, [pos(:text, :string, required: true)])

      assert {:error, "missing required argument text", search} ==
               Parser.parse(["search"], [search])
    end

    test "a missing required flag is an error" do
      add = spec(:add, [flag(:group, :string, required: true)])

      assert {:error, "missing required argument --group", add} ==
               Parser.parse(["add"], [add])
    end
  end

  describe "in:" do
    test "a flag value outside in: is an error" do
      add = spec(:add, [flag(:group, :string, in: ["income", "spending"])])

      assert {:error, ~s(invalid value "boats" for --group, expected one of: income, spending),
              add} == Parser.parse(["add", "--group", "boats"], [add])
    end

    test "a flag value inside in: is accepted and an omitted flag is not checked" do
      add = spec(:add, [flag(:group, :string, in: ["income", "spending"])])

      assert {:ok, __MODULE__, %{group: "income"}} =
               Parser.parse(["add", "--group", "income"], [add])

      assert {:ok, __MODULE__, %{group: ""}} = Parser.parse(["add"], [add])
    end

    test "every value of a multiple positional is checked" do
      cmd = spec(:pick, [pos(:colors, :string, multiple: true, in: ["red", "blue"])])

      assert {:error, ~s(invalid value "green" for colors, expected one of: red, blue), cmd} ==
               Parser.parse(["pick", "red", "green"], [cmd])
    end
  end

  describe "unknown flags and help" do
    test "an unknown flag lands in leftover" do
      add = spec(:add, [flag(:group, :string)])

      assert {:ok, __MODULE__, %{group: "", leftover: ["--bogus"]}} ==
               Parser.parse(["add", "--bogus"], [add])
    end

    test "--help and -h on a command without a :help arg return its spec" do
      import_spec = spec(:import, [pos(:files, :string, multiple: true)])

      assert {:help, import_spec} == Parser.parse(["import", "--help"], [import_spec])
      assert {:help, import_spec} == Parser.parse(["import", "-h"], [import_spec])
    end

    test "--help wins over a missing required argument" do
      search = spec(:search, [pos(:text, :string, required: true)])
      assert {:help, search} == Parser.parse(["search", "--help"], [search])
    end

    test "--help on a command with a :help arg is passed through" do
      import_spec = spec(:import, [flag(:help, :boolean)])

      assert {:ok, __MODULE__, %{help: true, leftover: []}} ==
               Parser.parse(["import", "--help"], [import_spec])
    end

    test "top level flags" do
      cmd = spec(:x, [])
      assert {:help, nil} == Parser.parse(["--help"], [cmd])
      assert :version == Parser.parse(["--version"], [cmd])
      assert {:completion, "zsh"} == Parser.parse(["--completion", "zsh"], [cmd])
    end

    test "no matching command and no fallback is an error" do
      assert {:error, "invalid flag or command", nil} == Parser.parse(["nope"], [spec(:x, [])])
    end
  end

  describe "fallback" do
    test "the fallback gets every arg and enforces its specs" do
      fallback = spec("", [pos(:name, :string, required: true), flag(:info, :boolean)])

      assert {:ok, __MODULE__, %{name: "bob", info: true, leftover: []}} ==
               Parser.parse(["bob", "--info"], [fallback])

      assert {:error, "missing required argument name", fallback} ==
               Parser.parse(["--info"], [fallback])
    end
  end
end
