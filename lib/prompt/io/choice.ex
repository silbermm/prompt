defmodule Prompt.IO.Choice do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @type t :: %Choice{
          default_answer: atom(),
          question: binary(),
          custom: any(),
          displayfn: (String.t() -> :ok)
        }

  defstruct [
    :default_answer,
    :question,
    :custom,
    :displayfn
  ]

  @doc ""
  def new(question, custom, options, displayfn) do
    [{k, _} | _rest] = custom

    %Choice{
      default_answer: Keyword.get(options, :default_answer, k),
      question: question,
      custom: custom,
      displayfn: displayfn
    }
  end

  defimpl Prompt.IO do
    def display(choice) do
      choice.displayfn.(
        "#{choice.question} #{choice_text(choice.custom, choice.default_answer)} "
      )

      choice
    end

    def evaluate(choice) do
      case read(:stdio, :line) do
        :eof -> :error
        {:error, _reason} -> :error
        answer -> _evaluate_choice(answer, choice)
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

    defp _evaluate_choice("\n", choice),
      do: choice.custom |> Keyword.take([choice.default_answer]) |> List.first() |> elem(0)

    defp _evaluate_choice(answer, choice) do
      choice.custom
      |> Enum.find(fn {_k, v} ->
        v |> String.downcase() == answer |> String.trim() |> String.downcase()
      end)
      |> elem(0)
    end
  end
end
