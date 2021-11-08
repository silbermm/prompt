defmodule Prompt.IO.Confirm do
  @moduledoc false

  alias __MODULE__
  alias Prompt.IO.Color
  import IO, only: [read: 2]

  @type t :: %Confirm{
          color: Color.t(),
          background_color: Color.t(),
          default_answer: :yes | :no,
          trim: boolean(),
          question: binary(),
          error: nil | binary(),
          answer: nil | binary(),
          mask_line: boolean(),
          displayfn: (String.t() -> :ok)
        }

  defstruct [
    :color,
    :background_color,
    :trim,
    :question,
    :answer,
    :error,
    :default_answer,
    :mask_line,
    :displayfn
  ]

  @spec new(binary(), keyword()) :: t()
  def new(question, options, displayfn \\ &IO.write(&1)) do
    %Confirm{
      color: Keyword.get(options, :color),
      background_color: Keyword.get(options, :background_color),
      trim: Keyword.get(options, :trim),
      default_answer: Keyword.get(options, :default_answer),
      question: question,
      answer: nil,
      error: nil,
      mask_line: Keyword.get(options, :mask_line, false),
      displayfn: displayfn
    }
  end

  defimpl Prompt.IO do
    @spec display(Prompt.IO.Confirm.t()) :: Prompt.IO.Confirm.t()
    def display(%Confirm{} = confirm) do
      :ok = confirm.displayfn.("#{confirm.question} #{confirm_text(confirm.default_answer)} ")
      confirm
    end

    @spec evaluate(Prompt.IO.Confirm.t()) :: :yes | :no | :error
    def evaluate(%Confirm{} = confirm) do
      case read(:stdio, :line) do
        :eof ->
          :error

        {:error, _reason} ->
          :error

        answer ->
          if confirm.mask_line do
            Prompt.Position.mask_line(1)
          end

          evaluate_confirm(%{confirm | answer: answer})
      end
    end

    defp confirm_text(:yes), do: "(Y/n):"
    defp confirm_text(:no), do: "(y/N):"

    defp evaluate_confirm(%Confirm{} = confirm) do
      confirm.answer
      |> String.trim()
      |> String.downcase()
      |> _evaluate_confirm(confirm)
    end

    defp _evaluate_confirm("y", _), do: :yes
    defp _evaluate_confirm("n", _), do: :no
    defp _evaluate_confirm("", confirm), do: confirm.default_answer
    defp _evaluate_confirm(_, confirm), do: confirm |> display() |> evaluate()
  end
end
