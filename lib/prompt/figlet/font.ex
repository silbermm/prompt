defmodule Prompt.Figlet.Font do
  @punctuation1 [ "!", "\"", "#", "$", "%", "&", "\'", "(", ")", "*", "+", ",", "-", ".", "/"]
  @punctuation2 [ ":", ";", "<", "=", ">", "?", "@"]
  @punctuation3 [ "[", "\\", "]", "^", "_", "`"]
  @numbers for x <- 0..9, do: "#{x}"
  @upper_letters for x <- ?A..?Z, do: <<x :: utf8>> 
  @lower_letters for x <- ?a..?z, do: <<x :: utf8>>
  @characters_list @punctuation1 ++ @numbers ++ @punctuation2 ++ @upper_letters ++ @punctuation3 ++ @lower_letters

  @font_file :prompt |> :code.priv_dir() |> Path.join("fonts/slant.flf")

  @stream File.stream!(@font_file)

  def get_character(character) do
    characters_list = @characters_list
    esc_seq = get_escape_sequence()
    char_index = get_character_index(character)
    _get_character(char_index, esc_seq)
  end

  def _get_character(char_index, esc_seq) do
    # find the where the esc_seq happens in the font file the (char_index + 2)th time
    #   the first time it appears it is the marker of what the sequence is
    #   and we need to add on because the char_index is 0 based
    @stream
    |> drop_intro
    |> Stream.chunk_every(Enum.count(esc_seq))
    |> Enum.at(char_index + 1)
  end

  defp get_escape_sequence() do
    @stream
    |> drop_intro
    |> Stream.map(&String.trim/1)
    |> Stream.take_while(fn line -> line != nil && 
      (String.starts_with?(line, "\d") || String.starts_with?(line, "$")) end)
    |> Stream.map(&remove_filler/1)
    |> Enum.to_list
  end

  defp remove_filler(<< "\d" <> char >>), do: char
  defp remove_filler(<< "$" <> char >>), do: char


  defp get_character_index(character) do
    indexes = Enum.with_index(@characters_list) 
    case Enum.find(indexes, fn {char, _} -> char == character end) do
      nil -> -1
      {_, idx} -> idx
    end
  end

  defp drop_intro(stream) do
    @stream
    |> Stream.drop_while(fn line -> 
      line = String.trim(line)
      !(String.starts_with?(line, "\d") || String.starts_with?(line, "$")) end)
  end
end
