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
  Build interactive command line interfaces.

    * `confirm/1`   prompt asks the user for a yes or no answer
    * `select/2`    prompt the user to choose one of several options
    * `text/1`      prompt for free form text
    * `password/1`  prompt for a password or other info that needs to be hidden
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
      Send the email? (Y/n): Y
      iex> :yes

      iex> Prompt.confirm("Send the email?", default_answer: :no)
      Send the email? (y/N): [enter]
      iex> :no

  """
  @spec confirm(String.t(), keyword()) :: :yes | :no | :error
  def confirm(question, opts \\ []) do
    default_answer = Keyword.get(opts, :default_answer, :yes)
    color = Keyword.get(opts, :color, ANSI.default_color())

    write(color <> "#{question} #{confirm_text(default_answer)}")
    write(ANSI.reset() <> " ")

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
  Display text on the screen and wait for the users text imput.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.text("Enter your email")
      Enter your email: t@t.com
      iex> t@t.com
  """
  @spec text(String.t(), keyword()) :: String.t()
  def text(display, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color <> "#{display}:")
    write(ANSI.reset() <> " ")

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> String.trim(answer)
    end
  end

  @doc """
  Displays options to the user denoted by numbers.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.select("Choose One", ["Choice A", "Choice B"])
        [0] Choice A
        [1] Choice B
      Choose One [0-1]: 1
      iex> "Choice B"
  """
  @spec select(String.t(), list(String.t()), keyword()) :: String.t() | :error
  def select(display, choices, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color)

    for {choice, number} <- Enum.with_index(choices) do
      write(ANSI.bright() <> ANSI.cursor_down() <> ANSI.cursor_left(1000) <> ANSI.cursor_right(2))
      write("[#{number}] #{choice}")
    end

    write(ANSI.cursor_down(2) <> ANSI.cursor_left(1000))
    write(ANSI.reset() <> color <> "#{display} [0-#{Enum.count(choices) - 1}]:")
    write(ANSI.reset() <> " ")

    read_select_choice(display, choices, opts)
  end

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
    write(ANSI.red() <> "Enter a number from 0-#{Enum.count(choices) - 1}: ")
    write(ANSI.reset())
    read_select_choice(display, choices, opts)
  end

  defp evaluate_choice_answer(answer, display, choices, opts) do
    answer_number = String.to_integer(answer)

    case Enum.at(choices, answer_number) do
      nil -> show_select_error(display, choices, opts)
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
      Enter your password: 
      iex> "password"
  """
  @spec password(String.t(), keyword()) :: String.t()
  def password(display, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color)

    write("#{display}: #{ANSI.conceal()}")

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
end
