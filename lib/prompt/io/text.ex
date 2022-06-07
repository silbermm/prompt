defmodule Prompt.IO.Text do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @type t() :: %Text{
          question: String.t(),
          color: any(),
          background_color: any(),
          trim: boolean(),
          min: integer(),
          max: integer()
        }

  defstruct [:question, :color, :background_color, :trim, :min, :max]

  @doc ""
  def new(question, options) do
    %Text{
      question: question,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: Keyword.get(options, :background_color),
      trim: Keyword.get(options, :trim),
      min: Keyword.get(options, :min, 0),
      max: Keyword.get(options, :max, 0)
    }
  end

  defimpl Prompt.IO do
    @spec display(Prompt.IO.Text.t()) :: Prompt.IO.Text.t()
    def display(txt) do
      [
        :reset,
        background_color(txt),
        txt.color,
        "#{txt.question}: ",
        :reset,
        without_newline(txt.trim)
      ]
      |> ANSI.format()
      |> write()

      txt
    end

    @spec evaluate(Prompt.IO.Text.t()) :: String.t() | :error_min | :error_max
    def evaluate(txt) do
      case read(:stdio, :line) do
        :eof ->
          :error

        {:error, _reason} ->
          :error

        answer ->
          answer = String.trim(answer)

          case {determine_min(answer, txt), determine_max(answer, txt)} do
            {false, _} -> :error_min
            {true, false} -> :error_max
            {true, true} -> answer
          end
      end
    end

    defp without_newline(true), do: ""
    defp without_newline(false), do: "\n"

    defp background_color(display) do
      case display.background_color do
        nil -> ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end

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
