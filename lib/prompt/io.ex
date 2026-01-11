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
  @moduledoc """
  Protocol for Terminal tooling functionality.

  All internal functionality implements this protocol.

  See `Prompt.IO` for more details
  """

  @doc """
  Given a `t:Prompt.IO.Terminal.t/0`, write the output to the terminal.

  ## Testing
  ...
  """
  @spec display(t()) :: t()
  def display(data)

  @doc """
  After displaying data, anything that needs read from the terminal happens here. 

  For workflows that don't need evaluation of input, simply return an empty list.
  """
  @spec evaluate(t()) :: any()
  def evaluate(data)
end

defmodule Prompt.IO do
  @moduledoc """
  Core module for dealing with dispatch of `Prompt.IO.Terminal` entities.

  See `Prompt` module for list of available functionality.

  ## Building new functionality
  Create a struct that implements the `Prompt.IO.Terminal` protocol.

  Calling `exec/1` with your new struct will invoke the correct behaviour.
  """
  alias Prompt.IO.Terminal

  @callback write(iolist()) :: :ok
  @doc """
  Writes provided `iodata` to the stdout.

  This is really just a delegation to `IO.write/2`, but is useful for testing purposes.
  """
  def write(data), do: Application.get_env(:prompt, :io, IO).write(data)

  @doc """
  Generates the correct ANSI code for background color given a color atom

  Defaults to `IO.ANSI.default_background/0`
  """
  @spec background_color(nil | atom()) :: atom()
  def background_color(nil), do: IO.ANSI.default_background()
  def background_color(res), do: String.to_atom("#{Atom.to_string(res)}_background")

  @doc """
  Executes the display and evaluation of structs that implement the Terminal protocol
  """
  @spec exec(Terminal.t()) :: any()
  def exec(terminal) do
    terminal
    |> Terminal.display()
    |> Terminal.evaluate()
  end
end
