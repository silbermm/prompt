defmodule Prompt.IO.Text do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @type t() :: %Text{question: String.t(), color: any(), background_color: any(), trim: boolean()}

  defstruct [:question, :color, :background_color, :trim]

  @doc ""
  def new(question, options) do
    %Text{
      question: question,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: Keyword.get(options, :background_color),
      trim: Keyword.get(options, :trim)
    }
  end

  defimpl Prompt.IO do
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

    def evaluate(_txt) do
      case read(:stdio, :line) do
        :eof -> :error
        {:error, _reason} -> :error
        answer -> String.trim(answer)
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
  end
end
