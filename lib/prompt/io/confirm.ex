defmodule Prompt.IO.Confirm do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @typep color ::
           :black
           | :blue
           | :cyan
           | :green
           | :light_black
           | :light_blue
           | :light_cyan
           | :light_green
           | :light_magneta
           | :light_red
           | :light_white
           | :light_yellow
           | :magenta
           | :red
           | :white
           | :yellow

  @type t :: %Confirm{
          color: color(),
          background_color: color(),
          trim: boolean(),
          question: binary(),
          error: nil | binary(),
          answer: nil | binary()
        }

  defstruct [:color, :background_color, :trim, :question, :answer, :error]

  def new(question, options) do
    %Confirm{
      color: Keyword.get(options, :color),
      background_color: Keyword.get(options, :background_color),
      trim: Keyword.get(options, :trim),
      question: question,
      answer: nil,
      error: nil
    }
  end

  def display(%Confirm{} = confirm) do
  end

  defp _confirm(question, options) do
    default_answer = Keyword.get(options, :default_answer)
    display("#{question} #{confirm_text(default_answer)} ", options)

    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        if Keyword.get(options, :mask_line, false) do
          Prompt.Position.mask_line(1)
        end

        evaluate_confirm(answer, question, options)
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
end
