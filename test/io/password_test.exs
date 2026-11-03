defmodule Prompt.IO.PasswordTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Password
  alias Prompt.IO.Terminal
  import Mox

  setup :verify_on_exit!

  test "when background color is set, then the ANSI escape sequence is printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[45m\e[39mEnter Password: \e[8m\e[0m"
      :ok
    end)

    "Enter Password"
    |> Password.new(background_color: :magenta)
    |> Terminal.display()
  end

  test "when text color is set, then the ANSI escape sequence is printed" do
    expect(Prompt.IO.Mock, :write, fn io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[49m\e[35mEnter Password: \e[8m\e[0m"
      :ok
    end)

    "Enter Password"
    |> Password.new(color: :magenta)
    |> Terminal.display()
  end
end
