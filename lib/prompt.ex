defmodule Prompt do
  @moduledoc """
  Build interactive command line interfaces.
  """

  alias IO.ANSI
  import IO

  @doc """
  Display a Y/n prompt

  ## Examples

  iex> Prompt.yes_or_no("Send the email?", [], fn -> :ok end)
  Send the email? (Y/n): Y
  iex> :ok

  """
  @spec yes_or_no(String.t(), keyword(), (() -> term())) :: term()
  def yes_or_no(question, options, yes_handler, no_handler \\ fn -> :error end) do
    write(ANSI.default_color() <> "#{question} (Y/n): ")

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error 
      answer -> evaluate_yes_or_no(answer, question, options, yes_handler, no_handler)
    end
  end

  defp evaluate_yes_or_no(answer, question, options, yes_handler, no_handler) do
    answer
    |> String.trim()
    |> String.downcase()
    |> _evaluate_yes_or_no(yes_handler, no_handler, question, options)
  end

  defp _evaluate_yes_or_no("y", yes_handler, _no_handler, _, _), do: yes_handler.()
  defp _evaluate_yes_or_no("n", _yes_handler, no_handler, _, _), do: no_handler.()
  defp _evaluate_yes_or_no("", yes_handler, _no_handler, _, _), do: yes_handler.()

  defp _evaluate_yes_or_no(_, yes_handler, no_handler, question, options) do
    puts("Unknown answer")
    yes_or_no(question, options, yes_handler, no_handler)
  end
end
