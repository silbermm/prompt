defmodule Prompt.IO.Choice do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @type t :: %Choice{
          default_answer: atom(),
          question: binary(),
          custom: any(),
          color: any(),
          background_color: any(),
          trim: boolean()
        }

  defstruct [
    :default_answer,
    :question,
    :custom,
    :color,
    :background_color,
    :trim
  ]

  @doc ""
  def new(question, custom, options) do
    [{k, _} | _rest] = custom

    %Choice{
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      trim: Keyword.get(options, :trim),
      default_answer: Keyword.get(options, :default_answer, k),
      question: question,
      custom: custom
    }
  end

  defimpl Prompt.IO do
    def display(choice) do
      [
        :reset,
        background_color(choice),
        choice.color,
        "#{choice.question} #{choice_text(choice.custom, choice.default_answer)} ",
        :reset,
        without_newline(choice.trim)
      ]
      |> ANSI.format()
      |> write()

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

    defp background_color(display) do
      case display.background_color do
        nil -> ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end

    defp without_newline(true), do: ""
    defp without_newline(false), do: "\n"
  end
end
