defmodule Prompt.Progress.Supervisor do
  @moduledoc false

  use DynamicSupervisor
  alias __MODULE__

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
