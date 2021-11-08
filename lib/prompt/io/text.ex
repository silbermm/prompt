defmodule Prompt.IO.Text do
  @moduledoc false

  alias __MODULE__
  import IO, only: [read: 2]

  @type t() :: %Text{question: String.t(), displayfn: (String.t() -> :ok)}

  defstruct [:question, :displayfn]

  @doc ""
  def new(question, _options, displayfn) do
    %Text{
      displayfn: displayfn,
      question: question
    }
  end

  defimpl Prompt.IO do
    def display(txt) do
      :ok = txt.displayfn.("#{txt.question}: ")
      txt
    end

    def evaluate(_txt) do
      case read(:stdio, :line) do
        :eof -> :error
        {:error, _reason} -> :error
        answer -> String.trim(answer)
      end
    end
  end
end
