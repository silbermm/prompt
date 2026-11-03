defmodule Prompt.IO.TextTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Terminal
  alias Prompt.IO.Text
  import Mox

  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[49m\e[39mWhat is your age?: \e[0m\e[0m"
      :ok
    end)

    "What is your age?"
    |> Text.new(trim: true)
    |> Terminal.display()
  end

  test "when trim is false, then the newline is printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[49m\e[39mWhat is your age?: \e[0m\n\e[0m"
      :ok
    end)

    "What is your age?"
    |> Text.new(trim: false)
    |> Terminal.display()
  end

  test "when background color is set, then the ANSI escape sequence is printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[45m\e[39mWhat is your age?: \e[0m\n\e[0m"
      :ok
    end)

    "What is your age?"
    |> Text.new(trim: false, background_color: :magenta)
    |> Terminal.display()
  end
end
