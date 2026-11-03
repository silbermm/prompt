# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

`prompt` is an Elixir library, published to Hex, for building interactive
command line applications. It has two layers:

- Terminal helpers in `Prompt`: `display`, `table`, `text`, `password`,
  `confirm`, `choice`, and `select`.
- A CLI framework in `Prompt.Router` and `Prompt.Command`: macros that
  declare commands and arguments, parse `argv`, and dispatch to command
  modules.

Licensed GPL-3.0-or-later. Every source file starts with the GPL header
comment. Keep it on new files.

Main development is on Codeberg at `https://codeberg.org/ahappydeath/prompt`.
GitHub is a mirror.

## Toolchain

The Nix flake is the only supported toolchain. There is no `.tool-versions`
and no Dockerfile.

- `nix develop` (or direnv via `.envrc`) gives the full dev shell: Erlang 28,
  Elixir 1.19, editor tooling, and jailed agents.
- `nix develop .#ci` gives the minimal shell CI uses: Erlang and Elixir only.
- The shell hook pins `MIX_HOME` and `HEX_HOME` to `.nix-mix` and `.nix-hex`
  inside the checkout. They are gitignored. On a fresh checkout run
  `mix local.hex --force && mix local.rebar --force` before `mix deps.get`.

Do not add asdf, Docker, or other toolchain files.

## Commands

All of these must pass before a change is done:

```
mix deps.get
mix compile --warnings-as-errors
mix format --check-formatted
mix graph --fail-above 1        # xref compile-connected graph, alias in mix.exs
mix credo --strict
mix test
mix dialyzer                    # slow on first run, builds a PLT
```

`make check` runs format, graph, credo, and dialyzer. Dialyzer runs with
`-Wunmatched_returns`, `:error_handling`, and `:underspecs`, so bind or
discard every return value and keep specs tight.

CI on Codeberg Woodpecker runs the same commands inside `nix develop .#ci`.
See `.woodpecker/`. A commit message containing `SKIPCI` skips the lint and
static analysis pipelines. A release event publishes to Hex.

## Layout

```
lib/prompt.ex            Public API. Validates options, builds a struct, calls Prompt.IO.exec/1.
lib/prompt/io.ex         Prompt.IO.Terminal protocol, Prompt.IO.write/1, Prompt.IO.exec/1.
lib/prompt/io/*.ex       One struct per prompt type, each implementing Prompt.IO.Terminal.
lib/prompt/io/examples.ex  Runnable demos: mix run -e "Prompt.IO.Examples.<fn>()"
lib/prompt/router.ex     `use Prompt.Router` plus the `command` and `arg` macros.
lib/prompt/command.ex    `use Prompt.Command` behaviour: init/1, process/1, help/0.
lib/prompt/table.ex      Table rendering.
test/io/*_test.exs       Mox-based tests of each Prompt.IO struct's output.
test/prompt_test.exs     CaptureIO tests of the public API.
test/prompt_module_test.exs  Router and Command integration.
```

There is no `config/` directory. The only app env key is `:prompt, :io`,
which names the module that writes to stdout. It defaults to `IO`.

## How the pieces fit

- Every public function in `Prompt` validates its options with
  `NimbleOptions`. Option schemas are module attributes next to the function
  and generate the docs. Add new options to the schema, not as ad hoc
  `Keyword.get` calls.
- Each prompt type is a struct that implements `Prompt.IO.Terminal` with
  `display/1`, which writes the prompt, and `evaluate/1`, which reads and
  returns the answer. `Prompt.IO.exec/1` calls them in order. To add a new
  prompt type, add a struct and impl under `lib/prompt/io/` and a thin
  wrapper in `lib/prompt.ex`. Do not put rendering logic in `prompt.ex`.
- All stdout goes through `Prompt.IO.write/1`. Never call `IO.write` or
  `IO.puts` directly from a `Prompt.IO` struct, or the tests cannot
  intercept it.
- `select` has two paths. On OTP 28 and newer it switches the shell to raw
  mode for arrow key navigation. Older OTP gets a numbered list.
  `Prompt.raw_mode_supported?/0` is the switch. Keep both paths working.
- Public functions in `Prompt` carry `@doc section: :input` or
  `@doc section: :output`. ExDoc groups by that attribute.

## Testing

- Tests under `test/io/` use Mox. `test/test_helper.exs` defines
  `Prompt.IO.Mock` and sets it as the `:io` module. Each test does
  `expect(Prompt.IO.Mock, :write, fn io -> ... end)` and asserts on
  `IO.iodata_to_binary(io)`, the flattened bytes. Do not pattern match on the
  nested list shape; it differs between Elixir versions.
- `test/test_helper.exs` forces `:ansi_enabled` on. Elixir otherwise drops
  color codes when stdout is not a TTY, which made color assertions pass only
  in a terminal. Leave that line in place.
- `test/prompt_test.exs` resets `:io` to the real `IO` in `setup` and uses
  `ExUnit.CaptureIO` to feed input and capture output. Use this style for
  end to end behavior of the public API.
- Multi-select tests are commented out because there is no good way to feed
  raw mode key sequences through CaptureIO yet.

## Conventions

- Work on a branch named like `feat/thing` or `chore/thing` and open a pull
  request against `main`.
- Record user-facing changes in `CHANGELOG.md` under `## Unreleased`, using
  the Keep a Changelog headings already there. Mark breaking changes with
  `**BREAKING:**`.
- The version lives only in `mix.exs`. Release candidates use the `-rcN`
  suffix.
- Docs are published to hexdocs. `README.md`, `CHANGELOG.md`, and `LICENSE`
  are ExDoc extras, so keep them rendering cleanly as Markdown.
- Do not commit `.nix-mix`, `.nix-hex`, `.erlang-history`, `_build`, or
  `deps`. They are already gitignored.
