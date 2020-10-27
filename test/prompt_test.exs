defmodule PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "confirm" do
    test "handle confirm" do
      assert capture_io("y", fn ->
               result = Prompt.confirm("Send the email?")
               assert result == :yes
             end) == "\e[0m\e[39mSend the email? (Y/n): \e[0m"
    end

    test "handle confirm - default" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :yes
             end) == "\e[0m\e[39mSend the email? (Y/n): \e[0m"
    end

    test "handle confirm - default to no" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", default_answer: :no)
               assert result == :no
             end) == "\e[0m\e[39mSend the email? (y/N): \e[0m"
    end

    test "handle confirm - no" do
      assert capture_io("n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :no
             end) == "\e[0m\e[39mSend the email? (Y/n): \e[0m"
    end

    test "handle confirm - unknown answer" do
      assert capture_io("asdf", fn ->
               Prompt.confirm("Send the email?", [])
             end) == "\e[0m\e[39mSend the email? (Y/n): \e[0m\e[0m\e[39mSend the email? (Y/n): \e[0m"
    end
  end

  describe "select" do
    test "returns selected option" do
      assert capture_io("0", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"])
               assert result == "t@t.com"
             end) ==
               "\e[39m\e[1m\n\e[1000D\e[2C[0] t@t.com\e[1m\n\e[1000D\e[2C[1] a@a.com\n\n\e[1000D\e[0m\e[39mWhich email? [0-1]:\e[0m "
    end

    test "requires choice from list" do
      assert capture_io("3", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) ==
               "\e[39m\e[1m\n\e[1000D\e[2C[0] t@t.com\e[1m\n\e[1000D\e[2C[1] a@a.com\n\n\e[1000D\e[0m\e[39mWhich email? [0-1]:\e[0m \e[31mEnter a number from 0-1: \e[0m "
    end

    test "requires valid number" do
      assert capture_io("one", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) ==
               "\e[39m\e[1m\n\e[1000D\e[2C[0] t@t.com\e[1m\n\e[1000D\e[2C[1] a@a.com\n\n\e[1000D\e[0m\e[39mWhich email? [0-1]:\e[0m \e[31mEnter a number from 0-1: \e[0m "
    end
  end

  describe "text" do
    test "returns input" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address")
               assert result == "t@t.com"
             end)
    end
  end
end
