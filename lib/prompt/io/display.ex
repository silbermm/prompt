defmodule Prompt.IO.Display do
  @moduledoc false

  alias __MODULE__
  import IO, only: [read: 2]

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

  defimpl Prompt.IO.Terminal do
    def display(text) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})

      # Put the cursor in the correct place
      start = [position(text.position, text.text)]

      content =
        if text.mask_line && text.from == :self do
          [
            :reset,
            background_color(text),
            text.color,
            text.text,
            :reset,
            " [Press Enter to continue]"
          ]
        else
          [
            :reset,
            background_color(text),
            text.color,
            text.text,
            :reset,
            without_newline(text.trim)
          ]
        end

      start ++ content
      |> IO.ANSI.format()
      |> Prompt.IO.write()

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

    defp position(:left, _), do: IO.ANSI.cursor_left(10_000)

    defp position(:right, content) when is_binary(content) do
      move_left = String.length(content)
      [IO.ANSI.cursor_right(10_000), IO.ANSI.cursor_left(move_left)]
    end

    defp position(:right, content) when is_list(content) do
      move_left =
        content
        |> List.flatten()
        |> Enum.reject(fn
          input when is_atom(input) -> true
          input when is_binary(input) -> String.starts_with?(input, "\\")
          _ -> true
        end)
        |> Enum.reduce(0, fn x, acc -> acc + String.length(x) end)
        |> dbg

      dbg content
      dbg move_left

      [IO.ANSI.cursor_right(10_000), IO.ANSI.cursor_left(move_left)]
    end

    defp background_color(display) do
      case display.background_color do
        nil -> IO.ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end
  end
end
