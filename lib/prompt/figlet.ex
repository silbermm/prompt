defmodule Prompt.Figlet do
  @moduledoc "Implementation of figlet in pure elixir"

  def print(text, opts \\ []) do
    # get letters from font file
    letters = get_letters(text, opts)
    # smush them together??

    # print them to the screen
    {_, r} = Enum.reduce(letters, {1, 0}, fn letter, {columns, _} ->
      rows = Enum.count(letter)
      next_columns = column_size(letter)
      Enum.each(letter, fn l -> 
        IO.write(IO.ANSI.cursor_right(columns))
        IO.write(l)
      end)
      IO.write(IO.ANSI.cursor_up(rows))
      {columns + next_columns, rows}
    end)

    IO.write(IO.ANSI.cursor_down(r + 1))
  end

  defp get_letters(text, _opts) do
    letter_lst = String.graphemes(text)
    Enum.map(letter_lst, &Prompt.Figlet.Font.get_character/1)
  end

  defp column_size(letter_list) do
    letter_list |> List.first() |> String.trim_trailing("\n") |> String.length 
  end
end
