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

defmodule Prompt.Router.Parser do
  @moduledoc false

  alias Prompt.Router.{ArgSpec, CommandSpec}

  @type result ::
          {:ok, module(), map()}
          | {:help, CommandSpec.t() | nil}
          | {:error, String.t(), CommandSpec.t() | nil}
          | :version
          | {:completion, String.t()}

  @doc """
  Parses `argv` against the router's command specs.
  """
  @spec parse([String.t()], [CommandSpec.t()]) :: result()
  def parse(argv, commands) do
    argv
    |> OptionParser.parse_head(
      switches: [help: :boolean, version: :boolean, completion: :string],
      aliases: [h: :help, v: :version]
    )
    |> parse_top(commands, argv)
  end

  defp parse_top({[help: true], _, _}, _, _), do: {:help, nil}
  defp parse_top({[version: true], _, _}, _, _), do: :version
  defp parse_top({[completion: shell], _, _}, _, _), do: {:completion, shell}

  defp parse_top({_, [head | rest], _}, commands, original) do
    case find_command(commands, head) do
      nil -> fallback(commands, original)
      command -> parse_command(command, rest)
    end
  end

  defp parse_top({_, [], _}, commands, original), do: fallback(commands, original)

  defp fallback(commands, original) do
    case find_command(commands, "") do
      nil -> {:error, "invalid flag or command", nil}
      command -> parse_command(command, original)
    end
  end

  defp find_command(commands, "") do
    Enum.find(commands, &(&1.name == ""))
  end

  defp find_command(commands, value) do
    Enum.find(commands, &(&1.name != "" and to_string(&1.name) == value))
  end

  defp parse_command(command, argv) do
    flags = Enum.filter(command.args, &(&1.kind == :flag))
    positionals = Enum.filter(command.args, &(&1.kind == :positional))
    auto_help? = not Enum.any?(flags, &(&1.name == :help))

    with {:ok, parsed, values, unknown} <- scan(argv, switches(flags, auto_help?), [], [], []),
         :help_not_requested <- help_requested(parsed, auto_help?, command),
         {:ok, assigned, unused} <- assign_positionals(positionals, values, %{}),
         :ok <- check_flags(flags, parsed) do
      data =
        flags
        |> Map.new(&{&1.name, Keyword.get(parsed, &1.name, default_value(&1))})
        |> Map.merge(assigned)
        |> Map.put_new(:leftover, unused ++ unknown)

      {:ok, command.module, data}
    else
      {:error, reason} -> {:error, reason, command}
      {:help, _} = help -> help
    end
  end

  defp switches(flags, auto_help?) do
    strict = Enum.map(flags, &{&1.name, &1.type})
    aliases = for %{short: short} = flag <- flags, short != nil, do: {short, flag.name}

    if auto_help? do
      aliases = if Keyword.has_key?(aliases, :h), do: aliases, else: [{:h, :help} | aliases]
      [strict: [{:help, :boolean} | strict], aliases: aliases]
    else
      [strict: strict, aliases: aliases]
    end
  end

  # OptionParser.parse/2 with strict: consumes the token after an unknown flag
  # and drops it, so walk the args with next/2 and keep unknown flags as typed.
  defp scan([], _opts, parsed, values, unknown),
    do: {:ok, Enum.reverse(parsed), Enum.reverse(values), Enum.reverse(unknown)}

  defp scan(["--" | rest], _opts, parsed, values, unknown),
    do: scan([], [], parsed, Enum.reverse(rest, values), unknown)

  defp scan([token | tail] = argv, opts, parsed, values, unknown) do
    case OptionParser.next(argv, opts) do
      {:ok, key, value, rest} -> scan(rest, opts, [{key, value} | parsed], values, unknown)
      {:undefined, _, _, _} -> scan(tail, opts, parsed, values, [token | unknown])
      {:invalid, opt, nil, _} -> {:error, "missing value for #{opt}"}
      {:invalid, opt, value, _} -> {:error, invalid_type(value, opt, opts)}
      {:error, _} -> scan(tail, opts, parsed, [token | values], unknown)
    end
  end

  defp invalid_type(value, opt, opts) do
    name = opt_name(opt, opts)
    type = Keyword.get(opts[:strict], name)
    ~s(invalid value "#{value}" for --#{name}, expected #{type})
  end

  defp opt_name("--" <> long, _opts), do: long |> String.split("=", parts: 2) |> hd() |> to_atom()

  defp opt_name("-" <> short, opts) do
    short = to_atom(short)
    Keyword.get(opts[:aliases], short, short)
  end

  defp to_atom(name), do: name |> String.replace("-", "_") |> String.to_existing_atom()

  defp help_requested(parsed, true, command) do
    if Keyword.get(parsed, :help, false), do: {:help, command}, else: :help_not_requested
  end

  defp help_requested(_parsed, false, _command), do: :help_not_requested

  defp assign_positionals([], values, acc), do: {:ok, acc, values}

  defp assign_positionals([%ArgSpec{multiple: true} = spec], values, acc) do
    with :ok <- check_required(spec, values),
         {:ok, converted} <- convert_all(spec, values),
         :ok <- check_in_all(spec, values, converted) do
      {:ok, Map.put(acc, spec.name, converted), []}
    end
  end

  defp assign_positionals([spec | specs], [], acc) do
    with :ok <- check_required(spec, []) do
      assign_positionals(specs, [], Map.put(acc, spec.name, nil))
    end
  end

  defp assign_positionals([spec | specs], [value | values], acc) do
    with {:ok, converted} <- convert(spec, value),
         :ok <- check_in(spec, value, converted) do
      assign_positionals(specs, values, Map.put(acc, spec.name, converted))
    end
  end

  defp check_required(%ArgSpec{required: true} = spec, []),
    do: {:error, "missing required argument #{label(spec)}"}

  defp check_required(_spec, _values), do: :ok

  defp convert_all(spec, values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, acc} ->
      case convert(spec, value) do
        {:ok, converted} -> {:cont, {:ok, [converted | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, converted} -> {:ok, Enum.reverse(converted)}
      error -> error
    end
  end

  defp convert(%ArgSpec{type: :integer} = spec, value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> {:error, invalid_positional(spec, value)}
    end
  end

  defp convert(%ArgSpec{type: :float} = spec, value) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _ -> {:error, invalid_positional(spec, value)}
    end
  end

  defp convert(_spec, value), do: {:ok, value}

  defp invalid_positional(spec, value),
    do: ~s(invalid value "#{value}" for #{spec.name}, expected #{spec.type})

  defp check_in_all(spec, values, converted) do
    values
    |> Enum.zip(converted)
    |> Enum.find_value(:ok, fn {value, conv} ->
      case check_in(spec, value, conv) do
        :ok -> nil
        error -> error
      end
    end)
  end

  defp check_in(%ArgSpec{in: nil}, _raw, _value), do: :ok

  defp check_in(%ArgSpec{in: allowed} = spec, raw, value) do
    if value in allowed do
      :ok
    else
      {:error,
       ~s(invalid value "#{raw}" for #{label(spec)}, expected one of: ) <>
         Enum.map_join(allowed, ", ", &to_string/1)}
    end
  end

  defp check_flags(flags, parsed) do
    Enum.find_value(flags, :ok, fn spec ->
      result =
        case Keyword.fetch(parsed, spec.name) do
          {:ok, value} -> check_in(spec, value, value)
          :error -> check_required(spec, [])
        end

      if result == :ok, do: nil, else: result
    end)
  end

  defp label(%ArgSpec{kind: :flag, name: name}), do: "--#{name}"
  defp label(%ArgSpec{name: name}), do: to_string(name)

  defp default_value(%{default: default}) when default != nil, do: default
  defp default_value(%{type: type}), do: type_default(type)

  defp type_default(:boolean), do: false
  defp type_default(:string), do: ""
  defp type_default(:integer), do: nil
  defp type_default(:float), do: nil
end
