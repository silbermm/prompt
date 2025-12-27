defmodule Prompt.Example do
  @moduledoc """
  Run-able examples of all the input and output functions.

  Each of these can be ran using `mix run`
  """
  import Prompt

  @doc """
  See `Prompt.select/2` for full select docs

  Run the following command to see an example of a single select
  ```
  mix run -e "Prompt.Example.single_select()" 
  ```
  """
  def single_select() do
    case select("This is an example single select menu. Pick One.", ["Erlang", "Elixir", "Gleam"]) do
      "Erlang" -> display("A very refined taste you have.", color: :red, trim: true)
      "Elixir" -> display("A very modern selection.", color: :magenta, trim: true)
      "Gleam" -> display("A very typsafe pic.", color: :green, trim: true)
    end

    case confirm("Pick again?", default_answer: :no) do
      :no ->
        nil

      :yes ->
        single_select()
    end
  end

  @doc """
  See `Prompt.select/2` for full select docs

  Run the following command to see an example of multi-select
  ```
  mix run -e "Prompt.Example.multi_select()" 
  ```
  """
  def multi_select() do
    selected =
      select(
        "This is an example multiple select menu. Choose all that apply.",
        ["Erlang", "Elixir", "Gleam"],
        color: :cyan,
        multi: true
      )

    display("You chose:", trim: true)

    for choice <- selected do
      display(choice, color: :yellow, trim: true)
    end

    selected =
      select(
        "This is an example multiple select menu with a custom select indicator. Choose all that apply.",
        ["Erlang", "Elixir", "Gleam"],
        color: :cyan,
        multi: true,
        select_indicator: "•"
      )

    display("You chose:", trim: true)

    for choice <- selected do
      display(choice, color: :yellow, trim: true)
    end
  end

  @doc """
  See `Prompt.display/2` for full docs on displaying text

  Run the following command to see an examples of the display function
  ```
  mix run -e "Prompt.Example.display()" 
  ```
  """
  @spec display :: none() | no_return()
  def display() do
    display("Here we show a colored list of words")

    Enum.each(
      ["one", "two", "three", "four", "five", "six", "seven"],
      &display(&1, color: :red, trim: true)
    )

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)

    display("\nHere we use a different background color")

    Enum.each(
      ["one", "two", "three", "four", "five", "six", "seven"],
      &display(&1, background_color: :yellow, color: :black, trim: true)
    )

    _ = Prompt.text("\nPress [Enter] to see the next example", trim: true)
    display("Here's an example of masking output when the user hits <enter>")
    display("password being displayed", mask_line: true)

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)
    display("You can add any `IO.ANSI` escape codes when displaying")
    display(["Current terminal width:", :bright, " #{Prompt.width()}"], trim: true)

    display(["Current terminal height:", :light_green, :bright, " #{Prompt.height()}"],
      trim: true
    )
  end
end
