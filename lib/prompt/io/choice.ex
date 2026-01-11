defmodule Prompt.IO.Choice do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [read: 2]

  @type t :: %Choice{
          content: list(),
          default_answer: atom(),
          question: binary(),
          custom: any(),
          color: any(),
          background_color: any(),
          trim: boolean(),
          mask_line: boolean()
        }

  defstruct [
    :content,
    :default_answer,
    :question,
    :custom,
    :color,
    :background_color,
    :trim,
    :mask_line
  ]

  @doc ""
  def new(question, custom, options) do
    [{k, _} | _rest] = custom

    background_color =
      options
      |> Keyword.get(:background_color)
      |> Prompt.IO.background_color()

    %Choice{
      content: [:reset],
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: background_color,
      trim: Keyword.get(options, :trim),
      default_answer: Keyword.get(options, :default_answer, k),
      question: question,
      custom: custom,
      mask_line: Keyword.get(options, :mask_line, false)
    }
  end

  def add_content(%Choice{content: content} = choice, to_add),
    do: %{choice | content: content ++ [to_add]}

  defimpl Prompt.IO.Terminal do
    def display(choice) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})

      choice =
        choice
        |> Choice.add_content([
          choice.background_color,
          choice.color,
          "#{choice.question} #{choice_text(choice.custom, choice.default_answer)} ",
          :reset
        ])
        |> maybe_with_newline()

      choice.content
      |> ANSI.format()
      |> Prompt.IO.write()

      choice
    end

    def evaluate(choice) do
      case read(:stdio, :line) do
        :eof ->
          :error

        {:error, _reason} ->
          :error

        answer when is_binary(answer) ->
          if choice.mask_line do
            Prompt.IO.Position.mask_line(1)
          end

          _evaluate_choice(answer, choice)

        answer when is_list(answer) ->
          if choice.mask_line do
            Prompt.IO.Position.mask_line(1)
          end

          _evaluate_choice(IO.chardata_to_string(answer), choice)
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
      chosen =
        choice.custom
        |> Enum.find(fn {_k, v} ->
          v |> String.downcase() == answer |> String.trim() |> String.downcase()
        end)

      case chosen do
        nil -> :invalid
        {result, _} -> result
      end
    end

    defp maybe_with_newline(%Choice{trim: true} = choice), do: choice
    defp maybe_with_newline(choice), do: Choice.add_content(choice, "\n")
  end
end
