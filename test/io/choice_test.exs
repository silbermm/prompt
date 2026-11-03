defmodule Prompt.IO.ChoiceTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Choice
  alias Prompt.IO.Terminal
  import Mox

  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    expect(Prompt.IO.Mock, :write, fn :stdio, io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[49m\e[39mContinue? (y/n): \e[0m\e[0m"
      :ok
    end)

    "Continue?"
    |> Choice.new([yes: "y", no: "n"], trim: true, default_answer: "y")
    |> Terminal.display()
  end

  test "when trim is false, then the newline is printed" do
    expect(Prompt.IO.Mock, :write, fn :stdio, io ->
      assert IO.iodata_to_binary(io) == "\e[0m\e[49m\e[39mContinue? (y/n): \e[0m\n\e[0m"
      :ok
    end)

    "Continue?"
    |> Choice.new([yes: "y", no: "n"], trim: false, default_answer: "y")
    |> Terminal.display()
  end
end
