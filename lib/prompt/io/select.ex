# Prompt - library to help create interactive CLI's in Elixir
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
          display: binary() | list(),
          choices: list(),
          error: nil | binary(),
          answer: nil | binary() | list(binary),
          current_choice: integer(),
          selected_choices: any(),
          select_keys: list(),
          select_indicator: binary()
        }

  defstruct [
    :color,
    :background_color,
    :multi,
    :trim,
    :display,
    :choices,
    :answer,
    :error,
    :current_choice,
    :selected_choices,
    :select_keys,
    :select_indicator
  ]

  @spec new(binary(), list(binary()), keyword()) :: t()
  def new(display, choices, opts) when is_list(choices) do
    select_keys = Keyword.get(opts, :select_keys, ["\t", " "])
    select_indicator = Keyword.get(opts, :select_indicator, ">")

    %Select{
      color: Keyword.get(opts, :color, ANSI.default_color()),
      background_color: Keyword.get(opts, :background_color),
      multi: Keyword.get(opts, :multi, false),
      trim: Keyword.get(opts, :trim, false),
      display: display,
      choices: choices,
      answer: nil,
      error: nil,
      current_choice: 0,
      selected_choices: MapSet.new(),
      select_keys: select_keys,
      select_indicator: select_indicator
    }
  end

  defimpl Prompt.IO.Terminal do
    @spec display(Prompt.IO.Select.t()) :: Prompt.IO.Select.t()
    def display(%Select{} = select) do
      if Prompt.raw_mode_supported?() do
        interactive_select(select)
      else
        legacy_select(select)
      end
    end

    defp interactive_select(select) do
      _ = :shell.start_interactive({:noshell, :raw})

      [
        :reset,
        ANSI.cursor_left(1000),
        background_color(select),
        select.color,
        "#{select.display}",
        "\n"
      ]
      |> ANSI.format()
      |> write()

      for {choice, number} <- Enum.with_index(select.choices) do
        [
          background_color(select),
          select.color,
          :bright,
          "\n",
          ANSI.cursor_left(1000),
          print_selector(select, number),
          select_text(choice)
        ]
        |> ANSI.format()
        |> write()
      end

      [
        ANSI.cursor_up(length(select.choices) - 1),
        ANSI.cursor_left(2000)
      ]
      |> ANSI.format()
      |> write()

      select
    end

    defp legacy_select(select) do
      for {choice, number} <- Enum.with_index(select.choices) do
        [
          :reset,
          background_color(select),
          select.color,
          :bright,
          "\n",
          ANSI.cursor_left(1000),
          ANSI.cursor_right(2),
          legacy_select_text(choice, number)
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

    defp print_selector(
           %Select{
             multi: false,
             current_choice: current_choice,
             select_indicator: select_indicator
           },
           number
         )
         when is_number(number) do
      (number == current_choice && "#{select_indicator} ") || "  "
    end

    defp print_selector(
           %Select{
             multi: true,
             current_choice: current_choice,
             selected_choices: selected,
             select_indicator: select_indicator
           },
           number
         )
         when is_number(number) do
      cond do
        MapSet.member?(selected, current_choice) ->
          "#{select_indicator} "

        :else ->
          "  "
      end
    end

    defp print_selector(%Select{
           multi: true,
           current_choice: current_choice,
           selected_choices: selected,
           select_indicator: select_indicator
         }) do
      cond do
        MapSet.member?(selected, current_choice) ->
          "#{select_indicator} "

        :else ->
          "  "
      end
    end

    defp print_selector(%Select{multi: false}), do: "  "

    @spec evaluate(Prompt.IO.Select.t()) :: binary() | list(binary)
    def evaluate(%Select{} = select) do
      if Prompt.raw_mode_supported?() do
        case read(:stdio, 30) do
          {:error, err} ->
            "ERR: #{inspect(err)}"

          char when is_binary(char) ->
            do_evaluate(char, select)

          :eof ->
            "ERR: reached end of file when reading input"
        end
      else
        case read(:stdio, :line) do
          :eof ->
            "ERR: reached end of file when reading input"

          {:error, reason} ->
            "ERR: #{inspect(reason)}"

          answer when is_binary(answer) ->
            answer
            |> String.trim()
            |> do_legacy_evaluate(select)

          answer when is_list(answer) ->
            answer
            |> IO.chardata_to_string()
            |> String.trim()
            |> do_legacy_evaluate(select)
        end
      end
    end

    defp do_legacy_evaluate(answer, select) do
      evaluate_choice_answer(answer, select)
      |> case do
        %Select{error: err} = s when not is_nil(err) ->
          s
          |> show_select_error()
          |> evaluate()

        %Select{answer: answer} ->
          answer
      end
    end

    defp do_evaluate(choice, %Select{multi: false} = select) when choice in ["\r"] do
      case Enum.at(select.choices, select.current_choice) do
        nil -> %Select{select | error: :invalid_answer}
        {_, result} -> %Select{select | answer: result}
        result -> %Select{select | answer: result}
      end
      |> case do
        %Select{error: err} = select when not is_nil(err) ->
          evaluate(select)

        %Select{answer: answer} = select ->
          remainder = length(select.choices) - select.current_choice

          [
            ANSI.cursor_down(remainder),
            ANSI.cursor_left(1000)
          ]
          |> ANSI.format()
          |> write()

          answer
      end
    end

    defp do_evaluate(choice, %Select{multi: true} = select) when choice in ["\r"] do
      answer_data =
        for idx <- select.selected_choices do
          case Enum.at(select.choices, idx) do
            nil -> nil
            {_, result} -> result
            result -> result
          end
        end

      if Enum.any?(answer_data, fn a -> a == nil end) do
        "ERR: invalid answer"
      else
        select = %Select{select | answer: answer_data}
        remainder = length(select.choices) - select.current_choice

        [
          ANSI.cursor_down(remainder + 2),
          ANSI.cursor_right(String.length(select.display) + 1),
          "\n",
          ANSI.cursor_left(1000)
        ]
        |> ANSI.format()
        |> write()

        answer_data
      end
    end

    defp do_evaluate(choice, select) when choice in ["\e[A", "k"] do
      cond do
        select.current_choice == 0 ->
          evaluate(select)

        select.current_choice > 0 ->
          current_choice = Enum.at(select.choices, select.current_choice)

          [
            ANSI.clear_line(),
            :reset,
            background_color(select),
            select.color,
            :bright,
            print_selector(select),
            select_text(current_choice),
            ANSI.cursor_up(),
            ANSI.cursor_left(1000)
          ]
          |> ANSI.format()
          |> write()

          select = %{select | current_choice: select.current_choice - 1}
          previous_choice = Enum.at(select.choices, select.current_choice)

          [
            ANSI.clear_line(),
            :reset,
            background_color(select),
            select.color,
            :bright,
            ANSI.cursor_left(1000),
            print_selector(select, select.current_choice),
            select_text(previous_choice),
            ANSI.cursor_left(1000)
          ]
          |> ANSI.format()
          |> write()

          evaluate(select)
      end
    end

    defp do_evaluate(choice, select) when choice in ["\e[B", "j"] do
      cond do
        select.current_choice == length(select.choices) - 1 ->
          evaluate(select)

        :else ->
          # get the choice from select.choices
          current_choice = Enum.at(select.choices, select.current_choice)

          [
            ANSI.clear_line(),
            :reset,
            background_color(select),
            select.color,
            :bright,
            print_selector(select),
            select_text(current_choice),
            ANSI.cursor_down(),
            ANSI.cursor_left(1000)
          ]
          |> ANSI.format()
          |> write()

          select = %{select | current_choice: select.current_choice + 1}
          next_choice = Enum.at(select.choices, select.current_choice)

          [
            ANSI.clear_line(),
            :reset,
            background_color(select),
            select.color,
            :bright,
            ANSI.cursor_left(1000),
            print_selector(select, select.current_choice),
            select_text(next_choice),
            ANSI.cursor_left(1000)
          ]
          |> ANSI.format()
          |> write()

          evaluate(select)
      end
    end

    defp do_evaluate(choice, %Select{multi: true} = select) do
      if choice in select.select_keys do
        if MapSet.member?(select.selected_choices, select.current_choice) do
          updated_selected_choices =
            MapSet.reject(select.selected_choices, &(&1 == select.current_choice))

          updated_select = %Select{select | selected_choices: updated_selected_choices}

          [
            " ",
            ANSI.cursor_left()
          ]
          |> write

          evaluate(updated_select)
        else
          select = %Select{
            select
            | selected_choices: MapSet.put(select.selected_choices, select.current_choice)
          }

          [
            "#{select.select_indicator}",
            ANSI.cursor_left()
          ]
          |> write

          evaluate(select)
        end
      else
        evaluate(select)
      end
    end

    defp do_evaluate(_choice, select), do: evaluate(select)

    defp select_text({dis, _}), do: "#{dis}"
    defp select_text(choice), do: "#{choice}"

    defp legacy_select_text({dis, _}, number), do: "[#{number + 1}] #{dis}"
    defp legacy_select_text(choice, number), do: "[#{number + 1}] #{choice}"

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
      %{select | error: nil}
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
