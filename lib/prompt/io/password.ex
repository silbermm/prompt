defmodule Prompt.IO.Password do
  @moduledoc false

  alias __MODULE__
  import IO, only: [read: 2]

  @type t :: %Password{
          content: list(),
          text: binary(),
          color: Prompt.IO.Color.t(),
          background_color: Prompt.IO.Color.t()
        }

  defstruct [:content, :text, :color, :background_color]

  def new(text, options) do
    background_color =
      options
      |> Keyword.get(:background_color)
      |> Prompt.IO.background_color()

    %Password{
      content: [:reset],
      text: text,
      color: Keyword.get(options, :color, IO.ANSI.default_color()),
      background_color: background_color
    }
  end

  def add_content(%Password{content: content} = password, to_add),
    do: %{password | content: content ++ [to_add]}

  defimpl Prompt.IO.Terminal do
    def display(password) do
      _ = Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :raw})

      password =
        Password.add_content(password, [
          password.background_color,
          password.color,
          password.text,
          ": ",
          IO.ANSI.conceal()
        ])

      password.content
      |> IO.ANSI.format()
      |> Prompt.IO.write()

      password
    end

    def evaluate(_password) do
      # case read(:stdio, :line) do
      case (Prompt.raw_mode_supported?() && :io.get_password()) || read(:stdio, :line) do
        :eof ->
          Prompt.IO.write(IO.ANSI.reset())
          :error

        {:error, _reason} ->
          Prompt.IO.write(IO.ANSI.reset())
          :error

        answer when is_binary(answer) ->
          Prompt.IO.write(IO.ANSI.reset())
          String.trim(answer)

        answer when is_list(answer) ->
          Prompt.IO.write(IO.ANSI.reset())

          answer
          |> IO.chardata_to_string()
          |> String.trim()
      end
    after
      Prompt.raw_mode_supported?() && :shell.start_interactive({:noshell, :cooked})
    end
  end
end
