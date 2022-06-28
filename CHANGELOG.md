# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added


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

[Unreleased]: https://github.com/silbermm/prompt/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/silbermm/prompt/releases/tag/v0.8.0
[0.7.4]: https://github.com/silbermm/prompt/releases/tag/v0.7.4
[0.6.3]: https://github.com/silbermm/prompt/releases/tag/v0.6.3
[0.6.2]: https://github.com/silbermm/prompt/releases/tag/v0.6.2
[0.6.1]: https://github.com/silbermm/prompt/releases/tag/v0.6.1
[0.6.0]: https://github.com/silbermm/prompt/releases/tag/v0.6.0
