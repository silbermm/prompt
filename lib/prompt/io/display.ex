defmodule Prompt.IO.Display do
  @moduledoc false

  alias __MODULE__
  import IO, only: [write: 1, read: 2]

  @type t() :: %Display{
          text: binary(),
          color: Prompt.IO.Color.t(),
          background_color: Prompt.IO.Color.t(),
          trim: bool(),
          mask_line: bool(),
          from: atom(),
          position: :left | :right
        }

  defstruct [:text, :color, :background_color, :trim, :mask_line, :from, :position]

  def new(txt, options) do
    %Display{
      text: txt,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: Keyword.get(options, :background_color),
      mask_line: Keyword.get(options, :mask_line),
      trim: Keyword.get(options, :trim),
      from: Keyword.get(options, :from),
      position: Keyword.get(options, :position)
    }
  end

  defimpl Prompt.IO do
    def display(text) do
      # Put the cursor in the correct place
      _ = position(text.position, text.text)

      if text.mask_line && text.from == :self do
        IO.ANSI.format([
          :reset,
          background_color(text),
          text.color,
          text.text,
          :reset,
          " [Press Enter to continue]"
        ])
        |> write()
      else
        [
          :reset,
          background_color(text),
          text.color,
          text.text,
          :reset,
          without_newline(text.trim)
        ]
        |> IO.ANSI.format()
        |> write()
      end

      text
    end

    def evaluate(text) do
      if text.mask_line && text.from == :self do
        case read(:stdio, :line) do
          :eof -> :error
          {:error, _reason} -> :error
          _ -> Prompt.Position.mask_line(1)
        end
      end

      :ok
    end

    defp without_newline(true), do: ""
    defp without_newline(false), do: "\n"

    defp position(:left, _), do: write(IO.ANSI.cursor_left(10_000))

    defp position(:right, content) do
      move_left = String.length(content)
      write(IO.ANSI.cursor_right(10_000) <> IO.ANSI.cursor_left(move_left))
    end

    defp background_color(display) do
      case display.background_color do
        nil -> IO.ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end
  end
end
