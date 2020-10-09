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
end
