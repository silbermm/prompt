defmodule Prompt.Figlet do
  @moduledoc "Implementation of figlet in pure elixir"

  def print(text, opts \\ []) do
    # get letters from font file
    letters = get_letters(text, opts)
    # smush them together??

    # print them to the screen
    _ = Enum.reduce(letters, 1, fn letter, columns ->
      rows = Enum.count(letter)
      next_columns = column_size(letter)
      Enum.each(letter, fn l -> 
        IO.write(IO.ANSI.cursor_right(columns))
        IO.write(l)
      end)
      IO.write(IO.ANSI.cursor_up(rows))
      columns + next_columns
    end)
  end

  defp get_letters(text, _opts) do
    letter_lst = String.graphemes(text)
    Enum.map(letter_lst, &Prompt.Figlet.Font.get_character/1)
  end

  defp column_size(letter_list) do
    next_columns = letter_list |> List.first() |> String.trim_trailing("\n") |> String.length
  end
end
