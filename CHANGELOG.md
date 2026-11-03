# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Changed
  - **BREAKING:** command flags may now appear after positional values; unknown flags still land in :leftover
  - Router parse errors (an unknown command with no fallback, a missing required argument, a value outside `in:`) print the reason to stderr
  - Router commands and args are now validated `CommandSpec`/`ArgSpec` structs; an unknown option to `arg` fails compilation. Added `positional/3`, `__commands__/0`, and the `help:` option to `use Prompt.Router`
### Fixed
  - Cleaned up all Credo reported issues
  - `display/2` and `table/2` no longer emit cursor-movement or color escape codes when ANSI is disabled (for example when output is redirected)
  - An invalid option to `display/2` or `table/2` now prints the error to stderr and returns `:error` instead of recursing forever
  - `text` `min`/`max` now count characters instead of bytes, and the code compiles without warnings on Elixir 1.20
  - `select/3` now returns `:error` at end of input (and on a read error) instead of the string `"ERR: ..."`

### Added
  - Generated usage: `--help` after a command prints the command module's `@moduledoc` (when available) then its arguments and options, and a parse error prints the reason followed by that usage. The router's `help/0` prints the `help:` option, then its `@moduledoc`, then generated usage; "Help not available" is gone. New overridable `command_help/1` callback
  - Router commands parse `positional/3` arguments; a `multiple: true` positional collects the remaining values into a list
  - `required: true` on `arg` and `positional`: a missing argument prints `missing required argument ...` and exits 1
  - `in:` on `arg` and `positional`: a value outside the list prints `invalid value ...` and exits 1
  - A value that does not parse as the `:integer` or `:float` type of its `arg` or `positional` prints `invalid value ...` and exits 1
  - `--help` and `-h` after a command that defines no `:help` arg print help and exit 0
  - `run/1` on routers: dispatches like `main/1` but returns the exit code instead of halting, and `use Prompt.Router, halt: false` makes `main/1` return the code too
  - Flake with a dev shell for development
  - `device:` option on `display/2` and `table/2` (`:stdio` or `:stderr`)
  - New `select` experience using Erlang 28 'raw' shell support
  - Bash and fish completions (`--completion bash`, `--completion fish`) alongside zsh; completions cover command names, flags, short flags, and `in:` values, and positionals no longer appear as flags

### Changed
  - Changed the way `display/2` handles iolists - Instead of writing each
    element in the list individually, it now passes the iolist straight through
    to the IO.write function
  - **BREAKING:** `handle_exit_value/1` returns the exit code instead of halting; `main/1` always halts unless `halt: false`
  - `{:error, reason}` returned from a command now prints the reason to stderr
  - **BREAKING:** moved `Prompt.Position` to `Prompt.IO.Position`
  - **BREAKING:** removed `Prompt.IO.write/1`. The `Prompt.IO` callback is now `write/2` (`device`, `iodata`), matching `IO.write/2`, so custom `:io` modules must implement `write/2`

### Removed
  - `.tool-versions`
  - Livebook example

## [0.10.1](https://codeberg.org/ahappydeath/prompt/releases/tag/v0.10.1) - 2025-01-31
### Updated
  - Moved Repo to Codeberg from Sourcehut
  - Dependencies including
    - nimble_options (1.1.1)

### Added
  - Generated command `--complete` that will build a simple zsh completion script

## [0.10.0]
### Updated
  - Forward all params to fallback command instead of failing when unable to match a command.

## [0.9.4]
### Updated
  - Documentation for building binary releases
  - Livebook Example

## [0.9.3]
### Added
  - Allow for border-less tables

## [0.9.2] - 2023-07-31
### Added
  - a `short` option for arguments

## [0.9.1] - 2023-07-17
### Fixed
  - Properly handle the charlist return from `IO.read/2`

## [0.9.0] - 2023-07-17
### Changed
  - when a command is passed in that is not recognized, print help to the screen

## [0.8.1] - 2022-12-13
### Added
  - Better support for halting the runtime when a command is finished
    - a new callback `handle_exit_value/1` that is overrideable and called after each command is done.

## [0.8.0] - 2022-06-27
### Added 
  - Prompt.Router to simplify creating commands
    - introduces the `command` and `arg` macros

## [0.7.4] - 2022-06-06
### Added
  - min and max validations for text entry

## [0.6.3] - 2021-11-28
### Added
  - use NimbleOptions to validate options
  - background_color as an option for displaying text

### Changed
  - modified the way to pass in text color
    * takes an atom now instead of an `IO.ANSI`color function
  - refactored `select/2` into it's own module
  - refactored `choice/2` into it's own module
  - refactored `confirm/2` into it's own module
  - refactored `text/2` into it's own module


## [0.6.2] - 2021-10-25
### Documentation
  - Added Livebook example as extra pages in hexdoc
  - Organized `Prompt` functions as Input / Output
  - Nested Modules for better readability
  - Updated ex_docs
  - Added GPL License file

## [0.6.1] - 2021-10-21
### Added
  - Many more tests
  - Livebook notebook with an example
  -

## [0.6.0] - 2021-10-17
### Added
  - a `help/0` callback and the ability to override

### Changed
  - Instead of taking a list of tuples for commands (`[{"command", Module"}]`), now take a Keyword list (`[command: Module]`)

[0.8.1]: https://github.com/silbermm/prompt/releases/tag/v0.8.1
[0.8.0]: https://github.com/silbermm/prompt/releases/tag/v0.8.0
[0.7.4]: https://github.com/silbermm/prompt/releases/tag/v0.7.4
[0.6.3]: https://github.com/silbermm/prompt/releases/tag/v0.6.3
[0.6.2]: https://github.com/silbermm/prompt/releases/tag/v0.6.2
[0.6.1]: https://github.com/silbermm/prompt/releases/tag/v0.6.1
[0.6.0]: https://github.com/silbermm/prompt/releases/tag/v0.6.0
