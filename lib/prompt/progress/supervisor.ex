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

defmodule Prompt.Progress.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  @doc false
  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: ProgressSupervisor)

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_progress(indicator) do
    spec = {Prompt.Progress.Indicator, indicator} 
    DynamicSupervisor.start_child(ProgressSupervisor, spec)
  end

  def stop_progress(progress) do
    DynamicSupervisor.terminate_child(ProgressSupervisor, progress)
  end

end
