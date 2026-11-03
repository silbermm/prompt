# Prompt - library to help create interactive CLI in Elixir
# Copyright (C) 2021  Matt Silbernagel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

defmodule Prompt.Router.ArgSpec do
  @moduledoc """
  One argument of a router command, built by `Prompt.Router.arg/3` or
  `Prompt.Router.positional/3`. Read it in an override of
  `c:Prompt.Router.command_help/1`; do not build it by hand.

  Fields:

    * `:name` - the atom key the parsed value is stored under. A flag is
      typed with dashes, so `:dry_run` is `--dry-run`.
    * `:type` - `:boolean`, `:string`, `:integer`, or `:float`.
    * `:kind` - `:flag` for `--name` options, `:positional` for bare values.
    * `:short` - the one letter alias of a flag, or `nil`.
    * `:default` - the value used when a flag is not given, or `nil`.
    * `:required` - whether the argument must be given.
    * `:in` - the allowed values, or `nil` for any value.
    * `:multiple` - whether a positional collects all remaining values.
    * `:doc` - the description shown in usage, or `nil`.
  """

  @type t :: %__MODULE__{
          name: atom(),
          type: :boolean | :string | :integer | :float,
          kind: :flag | :positional,
          short: atom() | nil,
          default: term(),
          required: boolean(),
          in: list() | nil,
          multiple: boolean(),
          doc: String.t() | nil
        }

  defstruct name: nil,
            type: :string,
            kind: :flag,
            short: nil,
            default: nil,
            required: false,
            in: nil,
            multiple: false,
            doc: nil

  @flag_schema [
    short: [type: :atom],
    default: [type: :any],
    required: [type: :boolean, default: false],
    in: [type: {:list, :any}],
    doc: [type: :string]
  ]

  @positional_schema [
    required: [type: :boolean, default: false],
    multiple: [type: :boolean, default: false],
    in: [type: {:list, :any}],
    doc: [type: :string]
  ]

  @doc false
  # Builds an `ArgSpec`, validating `opts` against the options allowed for
  # `kind`. Raises `ArgumentError` on an invalid option.
  @spec new!(atom(), atom(), :flag | :positional, keyword()) :: t()
  def new!(name, type, kind, opts) when is_atom(name) and kind in [:flag, :positional] do
    unless type in [:boolean, :string, :integer, :float] do
      raise ArgumentError, "invalid type #{inspect(type)} for #{inspect(name)}"
    end

    schema = if kind == :flag, do: @flag_schema, else: @positional_schema

    validated =
      case NimbleOptions.validate(opts, schema) do
        {:ok, validated} ->
          validated

        {:error, error} ->
          raise ArgumentError,
                "invalid options for #{kind} #{inspect(name)}: " <> Exception.message(error)
      end

    check_in_values!(name, type, kind, validated[:in])

    struct!(__MODULE__, [name: name, type: type, kind: kind] ++ validated)
  end

  # Parsed values are compared to in: with `in`, so `:info` never matches the
  # string "info". Catch the mismatch at compile time instead.
  defp check_in_values!(_name, :boolean, _kind, _values), do: :ok
  defp check_in_values!(_name, _type, _kind, nil), do: :ok

  defp check_in_values!(name, type, kind, values) do
    {check, plural} =
      case type do
        :string -> {&is_binary/1, "strings"}
        :integer -> {&is_integer/1, "integers"}
        :float -> {&is_float/1, "floats"}
      end

    if Enum.all?(values, check) do
      :ok
    else
      raise ArgumentError,
            "in: values for #{kind} #{inspect(name)} must be #{plural} to match its " <>
              "#{inspect(type)} type, got: #{inspect(values)}"
    end
  end

  @doc false
  # The name of a flag as it is typed on the command line, without the leading
  # dashes. Underscores become dashes, as `OptionParser` expects: `:dry_run`
  # becomes `"dry-run"`.
  @spec flag_name(t() | atom()) :: String.t()
  def flag_name(%__MODULE__{name: name}), do: flag_name(name)
  def flag_name(name) when is_atom(name), do: name |> Atom.to_string() |> String.replace("_", "-")
end

defmodule Prompt.Router.CommandSpec do
  @moduledoc """
  One command of a router, built by `Prompt.Router.command/2` and
  `Prompt.Router.command/3`. It is passed to `c:Prompt.Router.command_help/1`
  and to `Prompt.Router.Usage`; do not build it by hand.

  Fields:

    * `:name` - the command word as an atom or string, `""` for the fallback
      command.
    * `:module` - the `Prompt.Command` module that runs it, or `nil` for a
      group that only holds subcommands.
    * `:args` - the `Prompt.Router.ArgSpec` structs of its flags and
      positionals, in definition order.
    * `:subcommands` - nested `CommandSpec` structs, in definition order.
    * `:parents` - the command words typed before this command's name, for
      example `["categories"]` for `categories add`. `[]` at the top level.
  """

  @type t :: %__MODULE__{
          name: atom() | String.t(),
          module: module() | nil,
          args: [Prompt.Router.ArgSpec.t()],
          subcommands: [t()]
        }

  defstruct name: nil, module: nil, args: [], subcommands: []
end
