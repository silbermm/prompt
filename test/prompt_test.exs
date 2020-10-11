defmodule PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "handle yes or no question" do
    assert capture_io("y", fn ->
             result = Prompt.yes_or_no("Send the email?", [])
             assert result == :yes
           end) == "\e[39mSend the email? (Y/n): "
  end

  test "handle yes or no question - default" do
    assert capture_io("\n", fn ->
             result = Prompt.yes_or_no("Send the email?", [])
             assert result == :yes
           end) == "\e[39mSend the email? (Y/n): "
  end

  test "handle yes or no question - default to no" do
    assert capture_io("\n", fn ->
             result = Prompt.yes_or_no("Send the email?", default_answer: :no)
             assert result == :no
           end) == "\e[39mSend the email? (y/N): "
  end

  test "handle yes or no - no" do
    assert capture_io("n", fn ->
             result = Prompt.yes_or_no("Send the email?", [])
             assert result == :no
           end) == "\e[39mSend the email? (Y/n): "
  end

  test "handle yes or no - unknown answer" do
    assert capture_io("asdf", fn ->
             Prompt.yes_or_no("Send the email?", [])
           end) == "\e[39mSend the email? (Y/n): \e[39mSend the email? (Y/n): "
  end
end
