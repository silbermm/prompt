defmodule Prompt.IO.DisplayTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Display
  alias Prompt.IO.Terminal
  import Mox

  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    visible_content = "Print on the left"

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [
                     [[[[[] | _], "\e[10000D"], "\e[49m"], "\e[39m"] | _
                   ],
                   "Print on the left"
                 ]
                 | _
               ]
               | _
             ] =
               io

      :ok
    end)

    [:bright, visible_content]
    |> Display.new(trim: true, position: :left)
    |> Terminal.display()
  end

  test "when background color is set, then the ANSI escape sequence is printed" do
    visible_content = "Print on the left"

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [
                     [[[[[] | _], "\e[10000D"] | "\e[45m"], "\e[39m"] | "\e[1m"
                   ],
                   "Print on the left"
                 ]
                 | "\e[0m"
               ]
               | "\e[0m"
             ] =
               io

      :ok
    end)

    [:bright, visible_content]
    |> Display.new(trim: true, position: :left, background_color: :magenta)
    |> Terminal.display()
  end

  describe "when printing on the right" do
    test "then counting the visible content ignores atoms" do
      rightside_visible_content = "Print on the right"
      char_count = String.length(rightside_visible_content)
      expected_escape = "\e[#{char_count}D"

      expect(Prompt.IO.Mock, :write, fn io ->
        assert [
                 [
                   [
                     [
                       [
                         [
                           [
                             [[[[] | "\e[0m"], "\e[10000C"], ^expected_escape],
                             "\e[49m"
                           ],
                           "\e[39m"
                         ]
                         | "\e[1m"
                       ],
                       ^rightside_visible_content
                     ]
                     | _
                   ],
                   "\n"
                 ]
                 | _
               ] = io

        :ok
      end)

      [:bright, rightside_visible_content]
      |> Display.new(position: :right, trim: false)
      |> Terminal.display()
    end
  end

  for escape_code <- ["\n", "\t", IO.ANSI.bright()] do
    test "then counting the visible content ignores escape sequence #{escape_code}" do
      rightside_visible_content = "Print on the right"
      char_count = String.length(rightside_visible_content)
      expected_escape = "\e[#{char_count}D"

      expect(Prompt.IO.Mock, :write, fn io ->
        assert [
                 [
                   [
                     [
                       [
                         [
                           [
                             [[[[] | _], "\e[10000C"], ^expected_escape],
                             "\e[49m"
                           ],
                           "\e[39m"
                         ],
                         _
                       ],
                       ^rightside_visible_content
                     ]
                     | _
                   ],
                   "\n"
                 ]
                 | _
               ] = io

        :ok
      end)

      [unquote(escape_code), rightside_visible_content]
      |> Display.new(position: :right, trim: false)
      |> Terminal.display()
    end
  end
end
