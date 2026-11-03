defmodule Prompt.IO.DisplayTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Display
  alias Prompt.IO.Terminal
  import Mox

  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) ==
               "\e[0m\e[10000D\e[49m\e[39m\e[1mPrint on the left\e[0m\e[0m"

      :ok
    end)

    [:bright, "Print on the left"]
    |> Display.new(trim: true, position: :left)
    |> Terminal.display()
  end

  test "when background color is set, then the ANSI escape sequence is printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) ==
               "\e[0m\e[10000D\e[45m\e[39m\e[1mPrint on the left\e[0m\e[0m"

      :ok
    end)

    [:bright, "Print on the left"]
    |> Display.new(trim: true, position: :left, background_color: :magenta)
    |> Terminal.display()
  end

  describe "when printing on the right" do
    test "then counting the visible content ignores atoms" do
      visible = "Print on the right"
      move_left = "\e[#{String.length(visible)}D"

      expect(Prompt.IO.Mock, :write, fn io ->
        assert IO.iodata_to_binary(io) ==
                 "\e[0m\e[10000C#{move_left}\e[49m\e[39m\e[1m#{visible}\e[0m\n\e[0m"

        :ok
      end)

      [:bright, visible]
      |> Display.new(position: :right, trim: false)
      |> Terminal.display()
    end

    for escape_code <- ["\n", "\t", IO.ANSI.bright()] do
      test "then counting the visible content ignores escape sequence #{inspect(escape_code)}" do
        visible = "Print on the right"
        move_left = "\e[#{String.length(visible)}D"
        escape_code = unquote(escape_code)

        expect(Prompt.IO.Mock, :write, fn io ->
          assert IO.iodata_to_binary(io) ==
                   "\e[0m\e[10000C#{move_left}\e[49m\e[39m#{escape_code}#{visible}\e[0m\n\e[0m"

          :ok
        end)

        [escape_code, visible]
        |> Display.new(position: :right, trim: false)
        |> Terminal.display()
      end
    end
  end
end
