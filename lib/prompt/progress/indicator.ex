defmodule Prompt.Progress.Indicator do
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
