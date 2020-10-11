defmodule Prompt do
  @moduledoc """
  Build interactive command line interfaces.
  """

  alias IO.ANSI
  import IO

  @doc """
  Display a Y/n prompt.

  Sets 'Y' as the the default answer, allowing the user to just press the enter key. To make 'n' the default answer pass the option `default_answer: :no`

  ## Examples

      iex> Prompt.yes_or_no("Send the email?")
      Send the email? (Y/n): Y
      iex> :yes

      iex> Prompt.yes_or_no("Send the email?", default_answer: :no)
      Send the email? (y/N): [enter]
      iex> :no

  """
  @spec yes_or_no(String.t(), keyword()) :: :yes | :no | :error
  def yes_or_no(question, opts \\ []) do
    default_answer = Keyword.get(opts, :default_answer, :yes)
    write(ANSI.default_color() <> "#{question} #{yes_no_text(default_answer)} ")

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> evaluate_yes_or_no(answer, question, opts)
    end
  end

  defp yes_no_text(:yes), do: "(Y/n):"
  defp yes_no_text(:no), do: "(y/N):"

  defp evaluate_yes_or_no(answer, question, opts) do
    answer
    |> String.trim()
    |> String.downcase()
    |> _evaluate_yes_or_no(question, opts)
  end

  defp _evaluate_yes_or_no("y", _, _), do: :yes
  defp _evaluate_yes_or_no("n", _, _), do: :no
  defp _evaluate_yes_or_no("", _, opts), do: Keyword.get(opts, :default_answer, :yes)
  defp _evaluate_yes_or_no(_, question, opts), do: yes_or_no(question, opts)

  @doc """
  Display text on the screen and wait for the users text imput.

  ## Examples

      iex> Prompt.text_input("Enter your email")
      Enter your email: t@t.com
      iex> t@t.com
  """
  @spec text_input(String.t(), keyword()) :: String.t()
  def text_input(display, opts \\ []) do
    write(ANSI.default_color() <> "#{display}:")

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> String.trim(answer)
    end
  end

  @doc """
  Displays options to the user denoted by numbers.

  ## Examples

      iex> Prompt.select("You have many options", ["Choice A", "Choice B"])
      You have many options:
        [0] Choice A
        [1] Choice B
      Choose One [0-1]: 1
      iex> "Choice A"
  """
  @spec select(String.t(), list(String.t()), keyword()) :: String.t() | :error
  def select(display, choices, opts \\ []) do
    write(ANSI.default_color() <> "#{display}:")

    for {choice, number} <- Enum.with_index(choices) do
      write(ANSI.bright())
      write(ANSI.cursor_down())
      write(ANSI.cursor_left(1000))
      write(ANSI.cursor_right(2))
      write("[#{number}] #{choice}")
    end

    write(ANSI.cursor_down())
    write(ANSI.cursor_left(1000))
    write(ANSI.reset() <> "Choose One [0-#{Enum.count(choices) - 1}]: ")

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
end
