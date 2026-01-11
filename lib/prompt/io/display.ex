defmodule Prompt.IO.Display do
  @moduledoc false

  alias __MODULE__

  import IO, only: [read: 2]
  import Prompt.IO.ANSI

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
    background_color =
      options
      |> Keyword.get(:background_color)
      |> Prompt.IO.background_color()

    %Display{
      content: [:reset],
      text: txt,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: background_color,
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
    def display(display) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})

      display =
        if display.alt_buffer,
          do: Display.add_content(display, Prompt.IO.ANSI.alt_screen_buffer_on()),
          else: display

      display =
        display
        |> Display.add_content([position(display.position, display.text)])
        |> Display.add_content([
          display.background_color,
          display.color,
          display.text,
          :reset
        ])

      display =
        (display.mask_line && display.from == :self &&
           Display.add_content(display, [" [Press Enter to continue]"])) ||
          maybe_with_newline(display)

      display.content
      |> IO.ANSI.format()
      |> Prompt.IO.write()

      display
    end

    def evaluate(display) do
      if display.mask_line && display.from == :self do
        case read(:stdio, :line) do
          :eof -> :error
          {:error, _reason} -> :error
          _ -> Prompt.IO.Position.mask_line(1)
        end
      end

      :ok
    end

    defp maybe_with_newline(%Display{trim: true} = display), do: display
    defp maybe_with_newline(display), do: Display.add_content(display, "\n")

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
  end
end
