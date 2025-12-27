defmodule Prompt.ANSI do
  @moduledoc """
  Some common ANSI codes for the terminal.
  """

  @doc """
  Show an alternative screen buffer
  """
  def alt_screen_buffer_on do
    "\e[?1049h"
  end

  @doc """
  Hide the alternative screen buffer
  """
  def alt_screen_buffer_off do
    "\e[?1049l"
  end

  @doc "Hide the cursor"
  def hide_cursor do
    "\e[?25l"
  end

  @doc "Show the cursor"
  def show_cursor do
    "\e[?25h"
  end
end
