defmodule Prompt.IO.PasswordTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Password
  alias Prompt.IO.Terminal

  import Mox
  setup :verify_on_exit!

  test "when background color is set, then the ANSI escape sequence is printed" do
    visible_content = "Enter Password"

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [[[[[] | _] | _], "\e[39m"], ^visible_content] | _
                 ],
                 "\e[8m"
               ]
               | _
             ] = io

      :ok
    end)

    visible_content
    |> Password.new(background_color: :magenta)
    |> Terminal.display()
  end

  test "when text color is set, then the ANSI escape sequence is printed" do
    visible_content = "Enter Password"

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [
                     [[[[] | _], "\e[49m"] | "\e[35m"],
                     ^visible_content
                   ],
                   ": "
                 ],
                 "\e[8m"
               ]
               | _
             ] = io

      :ok
    end)

    visible_content
    |> Password.new(color: :magenta)
    |> Terminal.display()
  end
end
