# Prompt - library to help create interative CLI in Elixir
# Copyright (C) 2021  Matt Silbernagel
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
defmodule Prompt.IO.Select do
  @moduledoc false

  alias __MODULE__
  alias IO.ANSI
  import IO, only: [write: 1, read: 2]

  @typep color ::
           :black
           | :blue
           | :cyan
           | :green
           | :light_black
           | :light_blue
           | :light_cyan
           | :light_green
           | :light_magneta
           | :light_red
           | :light_white
           | :light_yellow
           | :magenta
           | :red
           | :white
           | :yellow

  @type t :: %Select{
          color: color(),
          background_color: color(),
          multi: boolean(),
          trim: boolean(),
          display: binary(),
          choices: list(binary()),
          error: nil | binary(),
          answer: nil | binary() | list(binary)
        }

  defstruct [:color, :background_color, :multi, :trim, :display, :choices, :answer, :error]

  @spec new(binary(), list(binary()), keyword()) :: t()
  def new(display, choices, opts) when is_list(choices) do
    %Select{
      color: Keyword.get(opts, :color, ANSI.default_color()),
      background_color: Keyword.get(opts, :background_color),
      multi: Keyword.get(opts, :multi),
      trim: Keyword.get(opts, :trim),
      display: display,
      choices: choices,
      answer: nil,
      error: nil
    }
  end

  defimpl Prompt.IO do
    @spec display(Prompt.IO.Select.t()) :: Prompt.IO.Select.t()
    def display(%Select{} = select) do
      for {choice, number} <- Enum.with_index(select.choices) do
        [
          :reset,
          background_color(select),
          select.color,
          :bright,
          "\n",
          ANSI.cursor_left(1000),
          ANSI.cursor_right(2),
          select_text(choice, number)
        ]
        |> ANSI.format()
        |> write()
      end

      [
        "\n",
        "\n",
        ANSI.cursor_left(1000),
        background_color(select),
        select.color,
        "#{select.display} [1-#{Enum.count(select.choices)}]:"
      ]
      |> ANSI.format()
      |> write()

      select
    end

    @spec evaluate(Prompt.IO.Select.t()) :: binary() | list(binary)
    def evaluate(%Select{} = select) do
      case read(:stdio, :line) do
        :eof ->
          %Select{select | error: "reached end of file when reading input"}

        {:error, reason} ->
          %Select{select | error: reason}

        answer ->
          answer
          |> String.trim()
          |> evaluate_choice_answer(select)
          |> case do
            %Select{error: err} = s when not is_nil(err) ->
              s
              |> show_select_error()
              |> evaluate()

            %Select{answer: answer} ->
              answer
          end
      end
    end

    defp select_text({dis, _}, number), do: "[#{number + 1}] #{dis}"
    defp select_text(choice, number), do: "[#{number + 1}] #{choice}"

    defp show_select_error(select) do
      text =
        if select.multi do
          "Enter numbers from 1-#{Enum.count(select.choices)} seperated by spaces: "
        else
          "Enter a number from 1-#{Enum.count(select.choices)}: "
        end

      [
        select.color,
        background_color(select),
        :bright,
        text
      ]
      |> ANSI.format()
      |> write

      # reset error
      %Select{select | error: nil}
    end

    defp evaluate_choice_answer(answers, %Select{multi: true} = select) do
      answer_numbers = String.split(answers, " ")

      answer_data =
        for answer_number <- answer_numbers do
          idx = String.to_integer(answer_number) - 1

          case Enum.at(select.choices, idx) do
            nil -> nil
            {_, result} -> result
            result -> result
          end
        end

      if Enum.any?(answer_data, fn a -> a == nil end) do
        %Select{select | error: :invalid_answer}
      else
        %Select{select | answer: answer_data}
      end
    catch
      _kind, error ->
        %Select{select | error: error}
    end

    defp evaluate_choice_answer(answer, %Select{multi: false} = select) do
      answer_number = String.to_integer(answer) - 1

      case Enum.at(select.choices, answer_number) do
        nil -> %Select{select | error: :invalid_answer}
        {_, result} -> %Select{select | answer: result}
        result -> %Select{select | answer: result}
      end
    catch
      _kind, error ->
        %Select{select | error: error}
    end

    defp background_color(select) do
      case select.background_color do
        nil -> ANSI.default_background()
        res -> String.to_atom("#{Atom.to_string(res)}_background")
      end
    end
  end
end
