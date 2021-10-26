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

defmodule Prompt do
  @moduledoc """
  Prompt provides a complete solution for building interactive command line applications.

  It's very flexible and can be used just to provide helpers for taking input from the user and displaying output.

  ## Basic Usage
  `import Prompt` includes utilities for:
    * printing to the screen          -> `display/1`
    * printing tables to the screen   -> `table/1`
    * asking for confirmation         -> `confirm/1`
    * picking from a list of choices  -> `select/1`
    * asking for passwords            -> `password/1`
    * free form text                  -> `text/1`

  ## Advanced usage
  To build a more advanced terminal application including sub-commands, define a module and `use Prompt, otp_app: :your_app` then build a keyword list of `Prompt.Command` that represents your commands and arguments and pass them to `c:process/2`.

  Doing this will give you the following options out of the box:

   * `--version` will pull your app version from mix.exs
   * `--help` will print your @moduledoc for help.

  ## Example

  ```elixir
  defmodule MyApp.CLI do
    @moduledoc "This will print when a user types `myapp --help` in the commandline"
    use Prompt, otp_app: :my_app

    # the entry point to your app, takes the command line args
    def main(argv), do:
      argv
      |> process(first: MyApp.CLI.FirstCommand)
    end
  end

  # a command
  defmodule MyApp.CLI.FirstCommand do
    @moduledoc "This prints when the help() command is called"
    use Prompt.Command

    @impl true
    def init(argv) do
      argv
      |> OptionParser.parse(
        strict: [help: :boolean, switch1: :boolean, swtich2: :boolean],
        aliases: [h: :help]
      )
      |> parse() #whatever you return from init will be what is passed to `process/1`
    end

    @impl true
    def process(%{help: true}, do: help()
    def process(%{switch1: switch1, switch2: switch2} do
      # do something based on the command and switches
      display("command output")
    end

    defp parse({[help: true], _, _}, do: %{help: true}
    defp parse({opts, _, _}) do
      switch1 = Keyword.get(opts, :switch1, false)
      switch2 = Keyword.get(opts, :switch2, false)
      %{help: false, switch1: switch1, switch2: switch2}
    end
  end
  ```

  The key in the Keyword list that you pass to process/2 is what you expect the user to use as a command, the value is the `Prompt.Command` module that will process the command.

  Once built, your command will be able to take a `first` subcommand.

  ```bash
  >>> my_app first --switch1
  command output
  ...
  >>> my_app --version
  0.0.1
  ```

  By default we try to display the @moduledoc when there is an error or when --help is passed in. This is overrideable though by implementing your own version of `c:help/0`.


  ## Building for Distribution

  There are a couple of different options for building a binary ready for distributing. Which ever approach you decide to use, you'll probably want to keep the docs instead of stripping them.
  For escripts, you'll add the following  to the escript key in mix.exs, if using Bakeware, you'll add it to the releases key.

  ```
  :strip_beams: [keep: ["Docs"]]
  ```

  ### Escript
  An [escript](https://hexdocs.pm/mix/master/Mix.Tasks.Escript.Build.html) is the most straightforward approach, but requires that erlang is already installed on the system.

  ### Bakeware
  This has been my preferred approach recently. [Bakeware](https://hexdocs.pm/bakeware/readme.html) uses releases to build a single executable binary that can be run on the system without the dependency on erlang or elixir.

  For Bakeware, I also set `export RELEASE_DISTRIBUTION=none` in `rel/env.sh.eex` and `rel/env.bat.eex` - unless you need erlang distribution in your CLI.

  For a complete example see [Slim](https://github.com/silbermm/slim_pickens)
  """

  alias IO.ANSI
  import IO

  @typedoc """
  A keyword list of commands and implementations of `Prompt.Command`

  ## Examples

      iex> commands = [help: CLI.Commands.Help, version: CLI.Commands.Version]

  """
  @type command_list() :: keyword(Prompt.Command)

  @typedoc """
  The list of strings coming from the commmand-line arguments
  """
  @type argv() :: list(String.t())

  @doc """
  Process the command line arguments based on the defined commands
  """
  @callback process(argv(), command_list()) :: non_neg_integer()

  @doc """
  Prints help to the screen when there is an error, or `--help` is passed as an argument
  """
  @callback help() :: :ok

  @doc section: :input
  @doc """
  Display a Y/n prompt.

  Sets 'Y' as the the default answer, allowing the user to just press the enter key. To make 'n' the default answer pass the option `default_answer: :no`

  Available options:

    * color: A color from the `IO.ANSI` module
    * default_answer: :yes or :no
    * mask_line: should the line be erased after the confirm

  ## Examples

      iex> Prompt.confirm("Send the email?")
      "Send the email? (Y/n):" Y
      iex> :yes

      iex> Prompt.confirm("Send the email?", default_answer: :no)
      "Send the email? (y/N):" [enter]
      iex> :no

  """
  @spec confirm(String.t(), keyword()) :: :yes | :no | :error
  def confirm(question, opts \\ []) do
    default_answer = Keyword.get(opts, :default_answer, :yes)
    opts = Keyword.put(opts, :trim, true)
    opts = Keyword.put(opts, :from, :confirm)
    display("#{question} #{confirm_text(default_answer)} ", opts)

    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        if Keyword.get(opts, :mask_line, false) do
          Prompt.Position.mask_line(1)
        end

        evaluate_confirm(answer, question, opts)
    end
  end

  defp confirm_text(:yes), do: "(Y/n):"
  defp confirm_text(:no), do: "(y/N):"

  defp evaluate_confirm(answer, question, opts) do
    answer
    |> String.trim()
    |> String.downcase()
    |> _evaluate_confirm(question, opts)
  end

  defp _evaluate_confirm("y", _, _), do: :yes
  defp _evaluate_confirm("n", _, _), do: :no
  defp _evaluate_confirm("", _, opts), do: Keyword.get(opts, :default_answer, :yes)
  defp _evaluate_confirm(_, question, opts), do: confirm(question, opts)

  @doc section: :input
  @doc """
  Display a choice prompt with custom answers.

  Takes a keyword list of answers in the form of atom to return and string to display.

  `[yes: "y", no: "n"]`

  will show "(y/n)" and return `:yes` or `:no` based on the choice.

  Available options:

    * default_answer: the default answer. If default isn't passed, the first is the default.
    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.choice("Save password?",
      ...>   [yes: "y", no: "n", regenerate: "r"],
      ...>   default_answer: :regenerate
      ...> )
      "Save Password? (y/n/R):" [enter]
      iex> :regenerate
  """
  @spec choice(String.t(), keyword(), keyword()) :: atom()
  def choice(question, custom, opts \\ []) do
    [{k, _} | _rest] = custom
    default_answer = Keyword.get(opts, :default_answer, k)
    opts = Keyword.put(opts, :trim, true)
    display("#{question} #{choice_text(custom, default_answer)} ", opts)

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> _evaluate_choice(answer, custom, default_answer)
    end
  end

  defp choice_text(custom_choices, default) do
    lst =
      Enum.map(custom_choices, fn {d, c} ->
        if d == default do
          String.upcase(c)
        else
          c
        end
      end)

    "(#{Enum.join(lst, "/")}):"
  end

  defp _evaluate_choice("\n", choices, default),
    do: choices |> Keyword.take([default]) |> List.first() |> elem(0)

  defp _evaluate_choice(answer, choices, _) do
    choices
    |> Enum.find(fn {_k, v} ->
      v |> String.downcase() == answer |> String.trim() |> String.downcase()
    end)
    |> elem(0)
  end

  @doc section: :input
  @doc """
  Display text on the screen and wait for the users text imput.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.text("Enter your email")
      "Enter your email:" t@t.com
      iex> t@t.com
  """
  @spec text(String.t(), keyword()) :: String.t()
  def text(display, opts \\ []) do
    opts = Keyword.put(opts, :trim, true)
    display("#{display}: ", opts)

    case read(:stdio, :line) do
      :eof -> :error
      {:error, _reason} -> :error
      answer -> String.trim(answer)
    end
  end

  @doc section: :input
  @doc """
  Displays options to the user denoted by numbers.

  Allows for a list of 2 tuples where the first value is what is displayed
  and the second value is what is returned to the caller.

  Available options:

    * color: A color from the `IO.ANSI` module
    * multi: true | false (default) - allow for the user to select multiple values?

  ## Examples

      iex> Prompt.select("Choose One", ["Choice A", "Choice B"])
      "  [1] Choice A"
      "  [2] Choice B"
      "Choose One [1-2]:" 1
      iex> "Choice A"

      iex> Prompt.select("Choose One", [{"Choice A", 1000}, {"Choice B", 1001}])
      "  [1] Choice A"
      "  [2] Choice B"
      "Choose One [1-2]:" 2
      iex> 1001

      iex> Prompt.select("Choose as many as you want", ["Choice A", "Choice B"], multi: true)
      "  [1] Choice A"
      "  [2] Choice B"
      "Choose as many as you want [1-2]:" 1 2
      iex> ["Choice A", "Choice B"]

  """
  @spec select(String.t(), list(String.t()) | list({String.t(), any()}), keyword()) ::
          any() | :error
  def select(display, choices, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    multi = Keyword.get(opts, :multi, false)
    opts = Keyword.put(opts, :multi, multi)

    write(color)

    for {choice, number} <- Enum.with_index(choices) do
      write(ANSI.bright() <> "\n" <> ANSI.cursor_left(1000) <> ANSI.cursor_right(2))
      write_choice(choice, number)
    end

    write("\n\n" <> ANSI.cursor_left(1000))
    write(ANSI.reset() <> color <> "#{display} [1-#{Enum.count(choices)}]:")
    reset()

    read_select_choice(display, choices, opts)
  end

  defp write_choice({dis, _}, number), do: write("[#{number + 1}] #{dis}")
  defp write_choice(choice, number), do: write("[#{number + 1}] #{choice}")

  defp read_select_choice(display, choices, opts) do
    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        answer
        |> String.trim()
        |> evaluate_choice_answer(display, choices, opts)
    end
  end

  defp show_select_error(display, choices, [multi: true] = opts) do
    write(ANSI.red() <> "Enter numbers from 1-#{Enum.count(choices)} seperated by spaces: ")
    reset()
    read_select_choice(display, choices, opts)
  end

  defp show_select_error(display, choices, opts) do
    write(ANSI.red() <> "Enter a number from 1-#{Enum.count(choices)}: ")
    reset()
    read_select_choice(display, choices, opts)
  end

  defp evaluate_choice_answer(answers, display, choices, [multi: true] = opts) do
    answer_numbers = String.split(answers, " ")

    answer_data =
      for answer_number <- answer_numbers do
        idx = String.to_integer(answer_number) - 1

        case Enum.at(choices, idx) do
          nil -> nil
          {_, result} -> result
          result -> result
        end
      end

    if Enum.any?(answer_data, fn a -> a == nil end) do
      show_select_error(display, choices, opts)
    else
      answer_data
    end
  catch
    _kind, _error ->
      show_select_error(display, choices, opts)
  end

  defp evaluate_choice_answer(answer, display, choices, opts) do
    answer_number = String.to_integer(answer) - 1

    case Enum.at(choices, answer_number) do
      nil -> show_select_error(display, choices, opts)
      {_, result} -> result
      result -> result
    end
  catch
    _kind, _error ->
      show_select_error(display, choices, opts)
  end

  @doc section: :input
  @doc """
  Prompt the user for input, but conceal the users typing.

  Available options:

    * color: A color from the `IO.ANSI` module

  ## Examples

      iex> Prompt.password("Enter your passsword")
      "Enter your password:"
      iex> "super_secret_passphrase"
  """
  @spec password(String.t(), keyword()) :: String.t()
  def password(display, opts \\ []) do
    color = Keyword.get(opts, :color, ANSI.default_color())
    write(color <> "#{display}: #{ANSI.conceal()}")

    case read(:stdio, :line) do
      :eof ->
        :error

      {:error, _reason} ->
        :error

      answer ->
        write(ANSI.reset())

        answer
        |> String.trim()
    end
  end

  @doc section: :output
  @doc """
  Writes text to the screen.

  Takes a single string argument or a list of strings where each item in the list will be diplayed on a new line.

  Available options:

    * color: A color from the `IO.ANSI` module
    * trim: true | false       --- Defaults to false (will put a `\n` at the end of the text
    * position: :left | :right --- Print the content starting from the leftmost position or the rightmost position
    * mask_line: true | false  --- Prompts the user to press enter and afterwards masks the line just printed
      * the main use case here is a password that you may want to show the user but hide after the user has a chance to write it down, or copy it.

  ## Examples

      iex> Prompt.display("Hello from the terminal!")
      "Hello from the terminal!"

      iex> Prompt.display(["Hello", "from", "the", "terminal"])
      "Hello"
      "from"
      "the"
      "terminal"
  """
  @spec display(String.t() | list(String.t()), keyword()) :: :ok
  def display(text, opts \\ []), do: _display(text, opts)

  defp _display(texts, opts) when is_list(texts) do
    _ = Enum.map(texts, &display(&1, opts))
    :ok
  end

  defp _display(text, opts) do
    trim = Keyword.get(opts, :trim, false)
    color = Keyword.get(opts, :color, ANSI.default_color())
    hide = Keyword.get(opts, :mask_line, false)
    from = Keyword.get(opts, :from, :self)

    if Keyword.has_key?(opts, :position) do
      position(opts, text)
    end

    if hide && from == :self do
      text =
        ANSI.reset() <>
          color <> text <> ANSI.reset() <> without_newline(true) <> " [Press Enter continue]"

      write(text)

      case read(:stdio, :line) do
        :eof -> :error
        {:error, _reason} -> :error
        _ -> Prompt.Position.mask_line(1)
      end
    else
      text = ANSI.reset() <> color <> text <> ANSI.reset() <> without_newline(trim)
      write(text)
    end
  end

  defp without_newline(true), do: ""
  defp without_newline(false), do: "\n"

  defp reset(), do: write(ANSI.reset() <> " ")

  defp position(opts, content) do
    opts
    |> Keyword.get(:position)
    |> _position(content)
  end

  defp _position(:left, _), do: write(ANSI.cursor_left(10_000))

  defp _position(:right, content) do
    move_left = String.length(content)
    write(ANSI.cursor_right(10_000) <> ANSI.cursor_left(move_left))
  end

  @doc section: :output
  @doc """
  Print an ASCII table of data. Requires a list of lists as input.

  Available Options

  * header: true | false (default)          --- use the first element as a header of the table
  * border: :normal (default) | :markdown   --- determine how the border is displayed

  ## Examples

      iex> Prompt.table([["Hello", "from", "the", "terminal!"],["this", "is", "another", "row"]])
      "
       +-------+------+---------+----------+
       | Hello | from | the     | terminal |
       | this  | is   | another | row      |
       +-------+------+---------+----------+
      "

      iex> Prompt.table([["One", "Two", "Three", "Four"], ["Hello", "from", "the", "terminal!"],["this", "is", "another", "row"]], header: true)
      "
       +-------+------+---------+----------+
       | One   | Two  | Three   | Four     |
       +-------+------+---------+----------+
       | Hello | from | the     | terminal |
       | this  | is   | another | row      |
       +-------+------+---------+----------+
      "
      
      iex> Prompt.table([["One", "Two", "Three", "Four"], ["Hello", "from", "the", "terminal!"],["this", "is", "another", "row"]], header: true, border: :markdown)
      "
       | One   | Two  | Three   | Four     |
       |-------|------|---------|----------|
       | Hello | from | the     | terminal |
       | this  | is   | another | row      |
      "

  """
  @spec table(list(list()), keyword()) :: :ok
  def table(matrix, opts \\ []) when is_list(matrix) do
    matrix
    |> build_table(opts)
    |> write()
  end

  @doc """
  Use this to get an iolist back of the table. Useful when you want an ascii `table/1` for
  other mediums like markdown files.
  """
  @spec table_data(list(list()), keyword()) :: [<<>> | [any()], ...]
  def table_data(matrix, opts \\ []) when is_list(matrix) do
    matrix
    |> build_table(opts)
  end

  defp build_table(matrix, opts) do
    tbl = Prompt.Table.new(matrix, opts)
    row_delimiter = Prompt.Table.row_delimiter(tbl)

    first =
      if Keyword.get(opts, :border) != :markdown do
        row_delimiter
      else
        ""
      end

    {next, matrix} =
      if Keyword.get(opts, :header, false) do
        # get the first 'row'
        headers = Enum.at(matrix, 0)
        {[Prompt.Table.row(tbl, headers), row_delimiter], Enum.drop(matrix, 1)}
      else
        {"", matrix}
      end

    rest =
      for row <- matrix do
        Prompt.Table.row(tbl, row)
      end

    last =
      if Keyword.get(opts, :border) != :markdown do
        row_delimiter
      else
        ""
      end

    [first, next, rest, last]
  end

  defmacro __using__(opts) do
    app = Keyword.get(opts, :otp_app, nil)

    if app == nil do
      raise ":otp_app is a required option when using Prompt"
    end

    quote(bind_quoted: [app: app]) do
      @behaviour Prompt
      import Prompt

      @app app

      @impl true
      def process(argv, commands) do
        argv
        |> OptionParser.parse_head(
          strict: [help: :boolean, version: :boolean],
          aliases: [h: :help, v: :version]
        )
        |> parse_opts(commands)
        |> _process()
      end

      defp _process(:help) do
        help()
        0
      end

      @impl true
      def help() do
        help =
          case Code.fetch_docs(__MODULE__) do
            {:docs_v1, _, :elixir, _, :none, _, _} -> "Help not available"
            {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} -> module_doc
            {:error, _} -> "Help not available"
            _ -> "Help not available"
          end

        display(help)
      end

      defp _process(:version) do
        {:ok, vsn} = :application.get_key(@app, :vsn)
        _ = display(List.to_string(vsn))
        0
      end

      defp _process({module, opts}) do
        cmd = apply(module, :init, [opts])
        apply(module, :process, [cmd])
      end

      defp parse_opts({[help: true], _, _}, _), do: :help
      defp parse_opts({[version: true], _, _}, _), do: :version

      defp parse_opts({[], [head | rest], _invalid}, defined_commands) do
        res =
          Enum.find(defined_commands, fn
            {h, _} when is_atom(h) -> head == Atom.to_string(h)
            {h, _} -> head == h
          end)

        if res == nil do
          :help
        else
          {_, mod} = res
          {mod, rest}
        end
      end

      defp parse_opts(_, _), do: :help

      defoverridable process: 2
      defoverridable help: 0
    end
  end
end
