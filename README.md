![prompt_with_text_lighter](https://user-images.githubusercontent.com/42816/115971052-5772c380-a514-11eb-8b43-dd49e81467f5.png)

![](https://github.com/silbermm/prompt/workflows/Build/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/prompt?style=flat-square)](https://hexdocs.pm/prompt/Prompt.html#content)

# Terminal UI Library for Elixir

* [Motivation](#motivation)
* [Installation](#installation)
* [Basic Usage](#basic-usage)
  * [Display text on the screen](#display-text-on-the-screen)
  * [Ask the user for input](#ask-the-user-for-input)
  * [Ask the user for a password](#ask-the-user-for-a-password)
  * [Ask the user for confirmation](#ask-the-user-for-confirmation)
  * [Custom confirmation choices](#custom-confirmation-choices)
  * [List of selections](#list-of-selections)
  * [Tables](#tables)
* [Advanced Usage](#advanced-usage-with-subcommands)
* [Example Application](#example)


[![Run in Livebook](https://livebook.dev/badge/v1/black.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fsilbermm%2Fprompt%2Fblob%2Fmain%2Fexample.livemd)


## Motivation

To create a really great development experience and API for Elixir developers that want to build commandline tools.

## Installation

Add `prompt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prompt, "~> 0.8.0"}
  ]
end
```

[Read the official documentation](https://hexdocs.pm/prompt/Prompt.html)

## Basic Usage
All of the following commands take a keyword list of options for things like text color and positioning.

### Display text on the screen
[Prompt.display/2](https://hexdocs.pm/prompt/Prompt.html#display/2)
```elixir
Prompt.display("Hello, world!")
```

### Ask the user for input
[Prompt.text/2](https://hexdocs.pm/prompt/Prompt.html#text/2)
Useful for prompting the user to enter freeform text
```elixir
Prompt.text("Enter info here")
```
Will display:
```bash
> Enter info here:
```
and wait for the user to enter text

### Ask the user for a password
[Prompt.password/2](https://hexdocs.pm/prompt/Prompt.html#password/2)
When you need to hide the input that the user types
```elixir
Prompt.password("Enter password")
```

### Ask the user for confirmation
[Prompt.confirm/2](https://hexdocs.pm/prompt/Prompt.html#confirm/2)
```elixir
Prompt.confirm("Are you sure?")
```
Will display:
```bash
> Are you sure? (Y/n):
```
and will allow the user to just press [enter] to confirm

If you'd prefer `n` to be the default pass the `default_answer` option
```elixir
Prompt.confirm("Are you sure?", default_answer: :no)
```
Returns `:yes` or `:no` based on the answer

### Custom confirmation choices
[Prompt.choice/2](https://hexdocs.pm/prompt/Prompt.html#choice/2)
Sometimes yes/no aren't the only choices a user can make, this method allows you to pass any choices as the confirmation.
```elixir
Prompt.choice("Accept, Reload or Cancel", accept: "a", reload: "r", cancel: "c")
```
displays
```bash
> Accept, Reload or Cancel (A/r/c):
```
Returns the key of the answer i.e `:accept`, `:reload` or `cancel` in this exammple

### List of selections
[Prompt.select/2](https://hexdocs.pm/prompt/Prompt.html#select/2)
To show the user a list of options to select from

```elixir
Prompt.select("Choose a protocol", ["file://", "ssh://", "ftp://"])
```
Displays:
```bash
  [1] file://
  [2] ssh://
  [3] ftp://
> Choose a protocol [1-3]:
```
and returns a string of their choice

### Tables
[Prompt.table/2](https://hexdocs.pm/prompt/Prompt.html#table/2)
To show a table of data
```elixir
Prompt.table([["Hello", "from", "the", "terminal!"],["this", "is", "another", "row"]])
```
Will display
```bash
> +-------+------+---------+----------+
  | Hello | from | the     | terminal |
  | this  | is   | another | row      |
  +-------+------+---------+----------+
```

## Advanced Usage with Subcommands
To use the more advanced features, see the [official documentation](https://hexdocs.pm/prompt/Prompt.html#module-subcommands)

## Example
For a complete example, take a look at [Slim - a cherry-picking tool](https://github.com/silbermm/slim_pickens)
