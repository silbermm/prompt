defmodule Prompt.IO.ChoiceTest do
  use ExUnit.Case, async: true

  alias Prompt.IO.Choice
  alias Prompt.IO.Terminal
  import Mox

  setup :verify_on_exit!

  test "when trim is true, then the newline is not printed" do
    visible_content = "Continue?"
    expected = "#{visible_content} (y/n): "

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [[[[] | "\e[0m"], "\e[49m"], "\e[39m"],
                   ^expected
                 ]
                 | _
               ]
               | _
             ] =
               io

      :ok
    end)

    visible_content
    |> Choice.new([yes: "y", no: "n"], trim: true, default_answer: "y")
    |> Terminal.display()
  end

  test "when trim is false, then the newline is printed" do
    visible_content = "Continue?"
    expected = "#{visible_content} (y/n): "

    expect(Prompt.IO.Mock, :write, fn io ->
      assert [
               [
                 [
                   [
                     [[[[] | "\e[0m"], "\e[49m"], "\e[39m"],
                     ^expected
                   ]
                   | _
                 ],
                 "\n"
               ]
               | _
             ] =
               io

      :ok
    end)

    visible_content
    |> Choice.new([yes: "y", no: "n"], trim: false, default_answer: "y")
    |> Terminal.display()
  end
end
