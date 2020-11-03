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

defmodule Prompt.Progress.Indicator do
  @moduledoc false

  use GenServer, restart: :temporary
  import IO
  alias IO.ANSI

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {:ok, 1, {:continue, :start}}
  end

  def handle_continue(:start, state) do
    Process.send(self(), :write_next, [])
    {:noreply, state}
  end

  def handle_info(:write_next, 1) do
    write(ANSI.cursor_left(1) <> "|")
    Process.send_after(self(), :write_next, 200)
    {:noreply, 2}
  end

  def handle_info(:write_next, 2) do
    write(ANSI.cursor_left(1) <> "/")
    Process.send_after(self(), :write_next, 200)
    {:noreply, 3}
  end

  def handle_info(:write_next, 3) do
    write(ANSI.cursor_left(1) <> "-")
    Process.send_after(self(), :write_next, 200)
    {:noreply, 4}
  end

  def handle_info(:write_next, 4) do
    write(ANSI.cursor_left(1) <> "\\")
    Process.send_after(self(), :write_next, 200)
    {:noreply, 1}
  end 
end
