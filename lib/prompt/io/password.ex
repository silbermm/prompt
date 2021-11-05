defmodule Prompt.IO.Password do
  @moduledoc false

  alias __MODULE__
  import IO, only: [write: 1, read: 2]

  @type t :: %Password{
          text: binary(),
          color: Prompt.IO.Color.t(),
          background_color: Prompt.IO.Color.t()
        }

  defstruct [:text, :color, :background_color]

  def new(text, options) do
    %Password{
      text: text,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: Keyword.get(options, :background_color)
    }
  end

  defimpl Prompt.IO do
    def display(password) do
      [
        :reset,
        background_color(password),
        password.color,
        password.text,
        ": ",
        IO.ANSI.conceal()
      ]
      |> IO.ANSI.format()
      |> write()

      password
    end

    def evaluate(_password) do
      case read(:stdio, :line) do
        :eof ->
          write(IO.ANSI.reset())
          :error

        {:error, _reason} ->
          write(IO.ANSI.reset())
          :error

        answer ->
          write(IO.ANSI.reset())
          String.trim(answer)
      end
    end

    defp background_color(password) do
      case password.background_color do
        nil -> IO.ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end
  end
end
