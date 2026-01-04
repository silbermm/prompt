defmodule Prompt.IO.TextTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Text
  import Mox
  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    visible_content = "What is your age?"

    expect(Prompt.IO.Mock, :write, fn io ->
      [
        [[[[[[] | _], "\e[49m"], "\e[39m"], "What is your age?: "] | _]
        | _
      ] = io

      :ok
    end)

    visible_content
    |> Text.new(trim: true)
    |> Prompt.IO.Terminal.display()
  end

  test "when trim is false, then the newline is printed" do
    visible_content = "What is your age?"

    expect(Prompt.IO.Mock, :write, fn io ->
      [
        [
          [[[[[[] | _], "\e[49m"], "\e[39m"], "What is your age?: "] | _],
          "\n"
        ]
        | _
      ] = io

      :ok
    end)

    visible_content
    |> Text.new(trim: false)
    |> Prompt.IO.Terminal.display()
  end

  test "when background color is set, then the ANSI escape sequence is printed" do
    visible_content = "What is your age?"

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [[[[[] | _] | _], "\e[39m"], "What is your age?: "] | _
                 ],
                 "\n"
               ]
               | _
             ] = io

      :ok
    end)

    visible_content
    |> Text.new(trim: false, background_color: :magenta)
    |> Prompt.IO.Terminal.display()
  end
end
