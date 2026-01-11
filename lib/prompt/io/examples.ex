defmodule Prompt.IO.Examples do
  @moduledoc """
  Runnable examples of all the input and output functions.

  Each of these can be ran using `mix run`
  """
  import Prompt

  @doc """
  See `Prompt.text/2` for full docs on text input

  Run the following command to examples of asking for user text input
  ```
  mix run -e "Prompt.IO.Examples.text()" 
  ```
  """
  def text do
    display("You can prompt for input with min and max number of charactors")

    case text("What is your age?", min: 1, max: 2, trim: true) do
      :error_min -> display("You need to have at least one number", color: :red)
      :error_max -> display("You are too old!", color: :red)
      answer -> display("Thanks for recording your age as #{answer}")
    end

    _ = Prompt.text("\nPress [Enter] to see the next example", trim: true)

    display("You can prompt for input with no max")

    case text("Write your book here", min: 1) do
      :error_min ->
        display("You need to have at least one charactor", color: :red)

      answer ->
        display("Repeating that back")
        display(answer, color: :yellow)
    end
  end

  @doc """
  See `Prompt.password/2` for full docs on password input

  Run the following command to examples of asking for concealed input
  ```
  mix run -e "Prompt.IO.Examples.password()" 
  ```
  """
  def password do
    display("You can prompt for passowrds and the input will be concealed")
    answer = password("Enter your password")
    display("Thanks for giving us your password of #{answer}", color: :green)
  end

  @doc """
  See `Prompt.select/2` for full select docs

  Run the following command to see an example of a single select
  ```
  mix run -e "Prompt.IO.Examples.single_select()" 
  ```
  """
  def single_select do
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
  mix run -e "Prompt.IO.Examples.multi_select()" 
  ```
  """
  def multi_select do
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
  mix run -e "Prompt.IO.Examples.display()" 
  ```
  """
  @spec display :: none() | no_return()
  def display do
    display("Here we show a colored list of words")

    Enum.each(
      ["one", "two", "three", "four", "five", "six", "seven"],
      &display(&1, color: :red)
    )

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)

    display("\nHere we use a different background color")

    Enum.each(
      ["one", "two", "three", "four", "five", "six", "seven"],
      &display(&1, background_color: :yellow, color: :black)
    )

    _ = Prompt.text("\nPress [Enter] to see the next example", trim: true)

    display("Here's an example of masking output when the user hits <enter>")
    display([:bright, "users password"], mask_line: true)

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)

    display([IO.ANSI.cursor(0, 0), "Or you can show sensitive content on the alt buffer instead"],
      alt_buffer: true
    )

    display([:bright, "password being displayed"])

    _ = Prompt.text("Press [Enter] to turn off the alt buffer", trim: true)
    display(Prompt.IO.ANSI.alt_screen_buffer_off())

    display("You can add any `IO.ANSI` escape codes when displaying")
    display(["Current terminal width:", :bright, " #{Prompt.width()}"])

    display(["Current terminal height:", :light_green, :bright, " #{Prompt.height()}"])

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)

    display("You also display on the right hand side", position: :right)
    display("Current terminal width:", trim: true)

    display([:bright, " #{Prompt.width()}"],
      position: :right,
      color: :black,
      background_color: :magenta
    )

    _ = Prompt.text("Press [Enter] to see the next example", trim: true)

    display([
      "Formatting output can be easily accomplished using ",
      :bright,
      ":io_lib.format/1",
      :reset,
      " from Erlang stdlib"
    ])

    display(:io_lib.format("Pi is approximately given by:~10.3f~n", [:math.pi()]))
  end
end
