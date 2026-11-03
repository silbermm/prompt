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
  @moduledoc false

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

  @doc """
  Builds an `ArgSpec`, validating `opts` against the options allowed for `kind`.
  Raises `ArgumentError` on an invalid option.
  """
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

    struct!(__MODULE__, [name: name, type: type, kind: kind] ++ validated)
  end

  @doc """
  The name of a flag as it is typed on the command line, without the leading
  dashes. Underscores become dashes, as `OptionParser` expects: `:dry_run`
  becomes `"dry-run"`.
  """
  @spec flag_name(t() | atom()) :: String.t()
  def flag_name(%__MODULE__{name: name}), do: flag_name(name)
  def flag_name(name) when is_atom(name), do: name |> Atom.to_string() |> String.replace("_", "-")
end

defmodule Prompt.Router.CommandSpec do
  @moduledoc false

  @type t :: %__MODULE__{
          name: atom() | String.t(),
          module: module() | nil,
          args: [Prompt.Router.ArgSpec.t()],
          subcommands: [t()]
        }

  defstruct name: nil, module: nil, args: [], subcommands: []
end
