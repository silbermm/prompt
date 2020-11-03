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

defmodule Prompt.Progress do
  @moduledoc """
  Progress indictors for the command line.

  Calling `Prompt.Progress.start/1` will write to the screen an
  'animated' loading indicator.

  Which indictor is shown depends on the options passed into `start/1`.
  By default, and the only option supported currently, will be a Spinner.

  Once done with the progress output, you can call `finish/1` - this will stop
  the output to the screen.
  """

  def start(opts \\ []) do
    Prompt.Progress.Supervisor.start_progress(opts)
  end

  def finish(progress) do
    Prompt.Progress.Supervisor.stop_progress(progress) 
  end
end
