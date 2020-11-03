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
