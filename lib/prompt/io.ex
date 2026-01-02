# Prompt - library to help create interactive CLI in Elixir
# Copyright (C) 2026  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defprotocol Prompt.IO.Terminal do
  @moduledoc false

  @spec display(t()) :: t()
  def display(data)

  @spec display(t()) :: iodata()
  def evaluate(data)
end

defmodule Prompt.IO do
  @moduledoc false
  @behaviour Prompt.IO.Terminal

  defdelegate display(data), to: Prompt.IO.Terminal
  defdelegate evaluate(data), to: Prompt.IO.Terminal

  @callback write(iolist()) :: :ok
  def write(data), do: Application.get_env(:prompt, :io, IO).write(data)
end
