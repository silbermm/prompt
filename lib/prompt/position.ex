# Prompt - library to help create interative CLI in Elixir
# Copyright (C) 2020  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule Prompt.Position do
  @moduledoc """
  Manipulate the position of the cursor and the display of previous text.
  """

  alias IO.ANSI
  import IO

  @doc """
  Clears the content from the previous `number` of lines
  and resets the cursor.
  """
  @spec clear_lines(pos_integer()) :: :ok
  def clear_lines(number) do
    1..number
    |> Enum.reduce("", &build_clear_lines_string/2)
    |> write
  end

  @spec _clear_up() :: String.t()
  defp _clear_up(), do: ANSI.cursor_up() <> ANSI.clear_line()

  defp build_clear_lines_string(_, str), do: str <> _clear_up()

  @doc """
  Mask the content on the terminal `relative_line` above.
  By default will clear the line and put `#######` in its place
  then move the cursor back to the current line.
  """
  @spec mask_line(pos_integer()) :: :ok
  def mask_line(relative_line) do
    line_output =
      ANSI.cursor_up(relative_line) <>
        ANSI.clear_line() <>
        ANSI.italic() <>
        ANSI.light_green() <>
        "#######" <>
        ANSI.reset() <> "\n"

    if relative_line - 1 <= 0 do
      write(line_output)
    else
      write(line_output <> ANSI.cursor_down(relative_line - 1))
    end
  end
end
