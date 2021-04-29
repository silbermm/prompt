# Prompt - library to help create interative CLI in Elixir
# Copyright (C) 2020  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule Prompt do
  @moduledoc """
  Helpers for building interactive command line interfaces.

    * `confirm/1`   prompt asks the user for a yes or no answer
    * `choice/2`    prompt for asking the user to make a custom confirmation choice
    * `select/2`    prompt the user to choose one of several options
    * `text/1`      prompt for free form text
    * `password/1`  prompt for a password or other info that needs to be hidden
    * `display/1`   displays text on the screen
  """

  alias IO.ANSI
  import IO

  @doc """
  Display a Y/n prompt.

  Sets 'Y' as the the default answer, allowing the user to just press the enter key. To make 'n' the default answer pass the option `default_answer: :no`

  Available options:

    * color: A color from the `IO.ANSI` module
    * default_answer: :yes or :no

  ## Examples

      iex> Prompt.confirm("Send the email?")
      "Send the email? (Y/n):" Y
      iex> :yes

      iex> Prompt.confirm("Send the email?", default_answer: :no)
      "Send the email? (y/N):" [enter]
      iex> :no

  """
  @spec confirm(String.t(), keyword()) :: :yes | :no | :error
  def confirm(question, opts \\ []) do
    default_answer = Keyword.get(opts, :default_answer, :yes)
    opts = Keyword.put(opts, :trim, true)
    display("#{question} #{confirm_text(default_answer)} ", opts)

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> evaluate_confirm(answer, question, opts)
    end
  end

  defp confirm_text(:yes), do: "(Y/n):"
  defp confirm_text(:no), do: "(y/N):"

  defp evaluate_confirm(answer, question, opts) do
    answer
    |> String.trim()
    |> String.downcase()
    |> _evaluate_confirm(question, opts)
  end

  defp _evaluate_confirm("y", _, _), do: :yes
  defp _evaluate_confirm("n", _, _), do: :no
  defp _evaluate_confirm("", _, opts), do: Keyword.get(opts, :default_answer, :yes)
  defp _evaluate_confirm(_, question, opts), do: confirm(question, opts)

  @doc """
  Display a choice prompt with custom answers.
  Takes a keyword list of answers in the form of atom to return and string to display. 

  `[yes: "y", no: "n"]`

  will show "(y/n)" and return `:yes` or `:no` based on the choice.

  Available options:

    * default_answer: the default answer. If default isn't passed, the first is the default.
    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.choice("Save password?", [yes: "y", no: "n", regenerate: "r"}, default_answer: :regenerate)
      "Save Password? (y/n/R):" [enter]
      iex> :regenerate
  """
  @spec choice(String.t(), keyword(), keyword()) :: atom()
  def choice(question, custom, opts \\ []) do
    [{k, _} | _rest] = custom
    default_answer = Keyword.get(opts, :default_answer, k)
    opts = Keyword.put(opts, :trim, true)
    display("#{question} #{choice_text(custom, default_answer)} ", opts)

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> _evaluate_choice(answer, custom, default_answer)
    end
  end

  defp choice_text(custom_choices, default) do
    lst =
      Enum.map(custom_choices, fn {d, c} ->
        if d == default do
          String.upcase(c)
        else
          c
        end
      end)

    "(#{Enum.join(lst, "/")}):"
  end

  defp _evaluate_choice("\n", choices, default),
    do: choices |> Keyword.take([default]) |> List.first() |> elem(0)

  defp _evaluate_choice(answer, choices, _) do
    choices
    |> Enum.find(fn {_k, v} ->
      v |> String.downcase() == answer |> String.trim() |> String.downcase()
    end)
    |> elem(0)
  end

  @doc """
  Display text on the screen and wait for the users text imput.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.text("Enter your email")
      "Enter your email:" t@t.com
      iex> t@t.com
  """
  @spec text(String.t(), keyword()) :: String.t()
  def text(display, opts \\ []) do
    opts = Keyword.put(opts, :trim, true)
    display("#{display}: ", opts)

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> String.trim(answer)
    end
  end

  @doc """
  Displays options to the user denoted by numbers.

  Allows for a list of 2 tuples where the first value is what is displayed
  and the second value is what is returned to the caller.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.select("Choose One", ["Choice A", "Choice B"])
      "  [1] Choice A"
      "  [2] Choice B"
      "Choose One [1-2]:" 1
      iex> "Choice A"

      iex> Prompt.select("Choose One", [{"Choice A", 1000}, {"Choice B", 1001}])
      "  [1] Choice A"
      "  [2] Choice B"
      "Choose One [1-2]:" 2
      iex> 1001

  """
  @spec select(String.t(), list(String.t()) | list({String.t(), any()}), keyword()) ::
          any() | :error
  def select(display, choices, opts \\ []) do
    # TODO: allow for the user to pass a list of tuples {display, return}
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color)

    for {choice, number} <- Enum.with_index(choices) do
      write(ANSI.bright() <> "\n" <> ANSI.cursor_left(1000) <> ANSI.cursor_right(2))
      write_choice(choice, number)
    end

    write("\n\n" <> ANSI.cursor_left(1000))
    write(ANSI.reset() <> color <> "#{display} [1-#{Enum.count(choices)}]:")
    reset()

    read_select_choice(display, choices, opts)
  end

  defp write_choice({dis, _}, number), do: write("[#{number + 1}] #{dis}")
  defp write_choice(choice, number), do: write("[#{number + 1}] #{choice}")

  defp read_select_choice(display, choices, opts) do
    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        answer
        |> String.trim()
        |> evaluate_choice_answer(display, choices, opts)
    end
  end

  defp show_select_error(display, choices, opts) do
    write(ANSI.red() <> "Enter a number from 1-#{Enum.count(choices)}: ")
    reset()
    read_select_choice(display, choices, opts)
  end

  defp evaluate_choice_answer(answer, display, choices, opts) do
    answer_number = String.to_integer(answer) - 1

    case Enum.at(choices, answer_number) do
      nil -> show_select_error(display, choices, opts)
      {_, result} -> result
      result -> result
    end
  catch
    _kind, _error ->
      show_select_error(display, choices, opts)
  end

  @doc """
  Prompt the user for input, but conceal the users typing.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.password("Enter your passsword")
      "Enter your password:"
      iex> "super_secret_passphrase"
  """
  @spec password(String.t(), keyword()) :: String.t()
  def password(display, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color <> "#{display}: #{ANSI.conceal()}")

    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        write(ANSI.reset())

        answer
        |> String.trim()
    end
  end

  @doc """
  Writes text to the screen.

  Takes a single string argument or a list of strings where each item in the list will be diplayed on a new line.

  Available options:

    * color: A color from the `IO.ANSI` module
    * trim: true | false       --- Defaults to false (will put a `\n` at the end of the text
    * position: :left | :right --- Print the content starting from the leftmost position or the rightmost position
    * mask_line: true | false  --- Prompts the user to press enter and afterwards masks the line just printed
      * the main use case here is a password that you may want to show the user but hide after the user has a chance to write it down, or copy it.

  ## Examples

      iex> Prompt.display("Hello from the terminal!")
      "Hello from the terminal!"

      iex> Prompt.display(["Hello", "from", "the", "terminal"])
      "Hello"
      "from"
      "the"
      "terminal"
  """
  @spec display(String.t() | list(String.t()), keyword()) :: :ok
  def display(text, opts \\ []), do: _display(text, opts)

  defp _display(texts, opts) when is_list(texts) do
    Enum.map(texts, &display(&1, opts))
  end

  defp _display(text, opts) do
    trim = Keyword.get(opts, :trim, false)
    color = Keyword.get(opts, :color, ANSI.default_color())
    hide = Keyword.get(opts, :mask_line, false)

    if Keyword.has_key?(opts, :position) do
      position(opts, text)
    end

    if hide do
      text =
        ANSI.reset() <>
          color <> text <> ANSI.reset() <> without_newline(true) <> " [Press Enter continue]"

      write(text)

      case read(:stdio, :line) do
        :eof -> :error
        {:error, _reason} -> :error
        _ -> Prompt.Position.mask_line(1)
      end
    else
      text = ANSI.reset() <> color <> text <> ANSI.reset() <> without_newline(trim)
      write(text)
    end
  end

  defp without_newline(true), do: ""
  defp without_newline(false), do: "\n"

  defp reset(), do: write(ANSI.reset() <> " ")

  defp position(opts, content) do
    opts
    |> Keyword.get(:position)
    |> _position(content)
  end

  defp _position(:left, _), do: write(ANSI.cursor_left(10_000))

  defp _position(:right, content) do
    move_left = String.length(content)
    write(ANSI.cursor_right(10_000) <> ANSI.cursor_left(move_left))
  end
end
