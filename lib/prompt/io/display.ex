defmodule Prompt.IO.Display do
  @moduledoc false

  alias __MODULE__

  import IO, only: [read: 2]
  import Prompt.ANSI

  @type t() :: %Display{
          content: list(),
          text: binary(),
          color: Prompt.IO.Color.t(),
          background_color: Prompt.IO.Color.t(),
          trim: bool(),
          mask_line: bool(),
          from: atom(),
          position: :left | :right,
          alt_buffer: boolean()
        }

  defstruct [
    :content,
    :text,
    :color,
    :background_color,
    :trim,
    :mask_line,
    :from,
    :position,
    :alt_buffer
  ]

  def new(txt, options) do
    %Display{
      content: [],
      text: txt,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: Keyword.get(options, :background_color),
      mask_line: Keyword.get(options, :mask_line),
      trim: Keyword.get(options, :trim),
      from: Keyword.get(options, :from),
      position: Keyword.get(options, :position),
      alt_buffer: Keyword.get(options, :alt_buffer, false)
    }
  end

  def add_content(%Display{content: content} = display, to_add),
    do: %{display | content: content ++ [to_add]}

  defimpl Prompt.IO.Terminal do
    def display(text) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})

      text =
        if text.alt_buffer,
          do: Display.add_content(text, Prompt.ANSI.alt_screen_buffer_on()),
          else: text

      # Put the cursor in the correct place
      text = Display.add_content(text, [position(text.position, text.text)])

      text =
        if text.mask_line && text.from == :self do
          Display.add_content(
            text,
            [
              :reset,
              background_color(text),
              text.color,
              text.text,
              :reset,
              " [Press Enter to continue]"
            ]
          )
        else
          Display.add_content(
            text,
            [
              :reset,
              background_color(text),
              text.color,
              text.text,
              :reset,
              without_newline(text.trim)
            ]
          )
        end

      text.content
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
          <<first::binary-size(1), _rest::binary>> when is_escape_code(first) -> true
          _ -> false
        end)
        |> Enum.reduce(0, fn x, acc -> acc + String.length(x) end)

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
