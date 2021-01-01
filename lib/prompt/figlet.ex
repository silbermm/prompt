defmodule Prompt.Figlet do
  @moduledoc "Implementation of figlet in pure elixir"

  def print(text, opts \\ []) do
    # get letters from font file
    letters = get_letters(text, opts)
    # smush them together??

    # print them to the screen
    Enum.each(letters, &IO.write/1)
  end

  defp get_letters(text, _opts) do
    letter_lst = String.graphemes(text)
    Enum.map(letter_lst, &Prompt.Figlet.Font.get_character/1)
  end
end
