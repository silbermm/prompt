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
    * picking from a list of choices  -> `select/2`
    * asking for passwords            -> `password/1`
    * free form text input            -> `text/1`

  ## Advanced usage
  See `Prompt.Router`

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

  @colors Prompt.IO.Color.all()

  @confirm_options NimbleOptions.new!(
                     color: [
                       type: {:in, @colors},
                       doc: "The text color. One of `#{Kernel.inspect(@colors)}`."
                     ],
                     background_color: [
                       type: {:in, @colors},
                       doc: "The background color. One of `#{Kernel.inspect(@colors)}`."
                     ],
                     default_answer: [
                       type: {:in, [:yes, :no]},
                       default: :yes,
                       doc: "The default answer to the confirmation."
                     ],
                     mask_line: [
                       type: :boolean,
                       default: false,
                       doc:
                         "If set to true, this will mask the current line by replacing it with `#####`. Useful when showing passwords in the terminal."
                     ],
                     trim: [type: :boolean, default: true, doc: false],
                     from: [type: :atom, default: :confirm, doc: false]
                   )
  @doc section: :input
  @doc """
  Display a Y/n prompt.

  Sets 'Y' as the the default answer, allowing the user to just press the enter key. To make 'n' the default answer pass the option `default_answer: :no`

  Supported options:
  #{NimbleOptions.docs(@confirm_options)}

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
    run(opts, @confirm_options, fn options ->
      Prompt.IO.Confirm.new(question, options)
    end)
  end

  @choice_options NimbleOptions.new!(
                    color: [
                      type: {:in, @colors},
                      doc: "The text color. One of `#{Kernel.inspect(@colors)}`."
                    ],
                    background_color: [
                      type: {:in, @colors},
                      doc: "The background color. One of `#{Kernel.inspect(@colors)}`."
                    ],
                    default_answer: [
                      type: :atom,
                      doc: "The default answer for the choices. Defaults to the first choice."
                    ],
                    trim: [type: :boolean, default: true, doc: false],
                    from: [type: :atom, default: :confirm, doc: false]
                  )

  @doc section: :input
  @doc """
  Display a choice prompt with custom answers.

  Takes a keyword list of answers in the form of atom to return and string to display.

  `[yes: "y", no: "n"]`

  will show "(y/n)" and return `:yes` or `:no` based on the choice.

  Supported options: 
  #{NimbleOptions.docs(@choice_options)}

  ## Examples

      iex> Prompt.choice("Save password?",
      ...>   [yes: "y", no: "n", regenerate: "r"],
      ...>   default_answer: :regenerate
      ...> )
      "Save Password? (y/n/R):" [enter]
      iex> :regenerate
  """
  @spec choice(String.t(), keyword(), keyword()) :: :error | atom()
  def choice(question, custom, opts \\ []) do
    run(opts, @choice_options, fn options ->
      Prompt.IO.Choice.new(question, custom, options)
    end)
  end

  @text_options NimbleOptions.new!(
                  color: [
                    type: {:in, @colors},
                    doc:
                      "The text color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                  ],
                  background_color: [
                    type: {:in, @colors},
                    doc:
                      "The background color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                  ],
                  trim: [type: :boolean, default: false, doc: false],
                  min: [
                    type: :integer,
                    default: 0,
                    doc: "The minimum charactors required for input"
                  ],
                  max: [
                    type: :integer,
                    default: 0,
                    doc: "The maximum charactors required for input"
                  ]
                )

  @doc section: :input
  @doc """
  Display text on the screen and wait for the users text imput.

  Supported options:
  #{NimbleOptions.docs(@text_options)}

  ## Examples

      iex> Prompt.text("Enter your email")
      "Enter your email:" t@t.com
      iex> t@t.com
  """
  @spec text(String.t(), keyword()) :: String.t() | :error | :error_min | :error_max
  def text(display, opts \\ []) do
    run(opts, @text_options, fn options ->
      Prompt.IO.Text.new(display, options)
    end)
  end

  @select_options NimbleOptions.new!(
                    color: [
                      type: {:in, @colors},
                      doc:
                        "The text color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                    ],
                    background_color: [
                      type: {:in, @colors},
                      doc:
                        "The background color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                    ],
                    multi: [
                      type: :boolean,
                      default: false,
                      doc: "Allows multiple selections from the options presented."
                    ],
                    trim: [type: :boolean, default: true, doc: false]
                  )

  @doc section: :input
  @doc """
  Displays options to the user denoted by numbers.

  Allows for a list of 2 tuples where the first value is what is displayed
  and the second value is what is returned to the caller.

  Supported options:
  #{NimbleOptions.docs(@select_options)}

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
    run(opts, @select_options, fn options ->
      Prompt.IO.Select.new(display, choices, options)
    end)
  end

  @password_options NimbleOptions.new!(
                      color: [
                        type: {:in, @colors},
                        doc:
                          "The text color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                      ],
                      background_color: [
                        type: {:in, @colors},
                        doc:
                          "The background color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                      ]
                    )

  @doc section: :input
  @doc """
  Prompt the user for input, but conceal the users typing.

  Supported options:
  #{NimbleOptions.docs(@password_options)}

  ## Examples

      iex> Prompt.password("Enter your passsword")
      "Enter your password:"
      iex> "super_secret_passphrase"
  """
  @spec password(String.t(), keyword()) :: String.t()
  def password(display, opts \\ []) do
    run(opts, @password_options, fn options ->
      Prompt.IO.Password.new(display, options)
    end)
  end

  @display_options NimbleOptions.new!(
                     color: [
                       type: {:in, @colors},
                       doc:
                         "The text color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                     ],
                     background_color: [
                       type: {:in, @colors},
                       doc:
                         "The background color. One of `#{Kernel.inspect(@colors)}`. Defaults to the terminal default."
                     ],
                     trim: [type: :boolean, default: false, doc: false],
                     from: [type: :atom, default: :self, doc: false],
                     position: [
                       type: {:in, [:left, :right]},
                       default: :left,
                       doc:
                         "Print the content starting from the leftmost position or the rightmost position"
                     ],
                     mask_line: [
                       type: :boolean,
                       default: false,
                       doc:
                         "If set to true, this will mask the current line by replacing it with `#####`. Useful when showing passwords in the terminal."
                     ]
                   )

  @doc section: :output
  @doc """
  Writes text to the screen.

  Takes a single string argument or a list of strings where each item in the list will be diplayed on a new line.


  Supported options:
  #{NimbleOptions.docs(@display_options)}

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
    run(opts, @display_options, fn options ->
      Prompt.IO.Display.new(text, options)
    end)
  end

  @table_options NimbleOptions.new!(
                   header: [
                     type: :boolean,
                     default: false,
                     doc: "Use the first element as the header for the table."
                   ],
                   border: [
                     type: {:in, [:normal, :markdown]}
                   ]
                 )

  @doc section: :output
  @doc """
  Print an ASCII table of data. Requires a list of lists as input.

  Supported options:
  #{NimbleOptions.docs(@table_options)}

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
    case NimbleOptions.validate(opts, @table_options) do
      {:ok, options} ->
        matrix
        |> build_table(options)
        |> write()

      {:error, err} ->
        display(err.message, error: true)
        :error
    end
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

  defp run(opts, validation, io) do
    case NimbleOptions.validate(opts, validation) do
      {:ok, options} ->
        io.(options)
        |> Prompt.IO.display()
        |> Prompt.IO.evaluate()

      {:error, err} ->
        display(err.message, error: true)
        :error
    end
  end
end
