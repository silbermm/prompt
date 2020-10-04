defmodule PromptTest do
  use ExUnit.Case
  doctest Prompt

  test "greets the world" do
    assert Prompt.hello() == :world
  end
end
