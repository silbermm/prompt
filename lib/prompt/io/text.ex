defmodule Prompt.IO.Text do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [read: 2]

  @type t() :: %Text{
          content: list(),
          question: String.t(),
          color: any(),
          background_color: any(),
          trim: boolean(),
          min: integer(),
          max: integer()
        }

  defstruct [:content, :question, :color, :background_color, :trim, :min, :max]

  @doc ""
  def new(question, options) do
    background_color =
      options
      |> Keyword.get(:background_color)
      |> Prompt.IO.background_color()

    %Text{
      content: [:reset],
      question: question,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: background_color,
      trim: Keyword.get(options, :trim),
      min: Keyword.get(options, :min, 0),
      max: Keyword.get(options, :max, 0)
    }
  end

  def add_content(%Text{content: content} = text, to_add),
    do: %{text | content: content ++ [to_add]}

  defimpl Prompt.IO.Terminal do
    def display(text) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})

      text =
        text
        |> Text.add_content([
          text.background_color,
          text.color,
          "#{text.question}: ",
          :reset
        ])
        |> maybe_with_newline()

      text.content
      |> ANSI.format()
      |> Prompt.IO.write()

      text
    end

    @spec evaluate(Prompt.IO.Text.t()) :: String.t() | :error_min | :error_max
    def evaluate(txt) do
      case read(:stdio, :line) do
        :eof ->
          :error

        {:error, _reason} ->
          :error

        answer when is_binary(answer) ->
          answer
          |> String.trim()
          |> do_evaluate(txt)

        answer when is_list(answer) ->
          answer
          |> IO.chardata_to_string()
          |> String.trim()
          |> do_evaluate(txt)
      end
    end

    defp do_evaluate(answer, txt) do
      case {determine_min(answer, txt), determine_max(answer, txt)} do
        {false, _} -> :error_min
        {true, false} -> :error_max
        {true, true} -> answer
      end
    end

    def maybe_with_newline(%{trim: true} = text), do: text
    def maybe_with_newline(text), do: Text.add_content(text, "\n")

    defp determine_min(answer, %Text{min: min}) when min > 0 do
      min_size = min * 8

      case answer do
        <<_val::bitstring-size(min_size), _rest::binary>> ->
          true

        _ ->
          false
      end
    end

    defp determine_min(_answer, %Text{}), do: true

    defp determine_max(answer, %Text{max: max}) when max > 0 do
      max_size = max * 8

      case answer do
        <<_val::bitstring-size(max_size), rest::binary>> when rest != "" ->
          false

        _ ->
          true
      end
    end

    defp determine_max(_answer, %Text{}), do: true
  end
end
