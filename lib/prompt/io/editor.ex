defmodule Prompt.IO.Editor do
  @moduledoc false
  use GenServer

  alias __MODULE__

  @type t :: %Editor{initial_text: binary(), pid: pid()}

  defstruct [:initial_text, :pid]

  def start(editor_text), do: GenServer.start(__MODULE__, editor_text)
  def init(editor_text) do
    {:ok, editor_text, {:continue, :start_editor}}
  end
  
  

  def new(initial_text) do
    %Editor{initial_text: initial_text, pid: nil}
  end

  defimpl Prompt.IO do
    def display(editor) do
      pid = send(:user_drv, {self(), {:open_editor, editor.initial_text}})
      %Editor{editor | pid: pid}
    end

    def evaluate(editor) do
      receive do
        data ->
          inspect(data)
      end
    end
  end
end
