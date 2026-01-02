defmodule Prompt.IO.DisplayTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Display

  import Mox

  setup :verify_on_exit!

  describe "when printing on the right" do
    test "then counting the content ignores escape sequences" do
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
                           [[[[[], "\e[10000C"], ^expected_escape] | "\e[0m"], "\e[49m"],
                           "\e[39m"
                         ],
                         "\e[1m"
                       ],
                       "Print on the right"
                     ]
                     | "\e[0m"
                   ],
                   "\n"
                 ]
                 | "\e[0m"
               ] = io

        :ok
      end)

      d = Display.new([IO.ANSI.bright(), rightside_visible_content], position: :right, trim: false)
      Prompt.IO.display(d)
    end
  end
end
