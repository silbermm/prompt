![prompt_with_text_lighter](https://user-images.githubusercontent.com/42816/115971052-5772c380-a514-11eb-8b43-dd49e81467f5.png)

![](https://github.com/silbermm/prompt/workflows/Build/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/prompt?style=flat-square)](https://hexdocs.pm/prompt/Prompt.html#content)

**STILL A WORK IN PROGRESS**

Easily build interactive CLI's in Elixir.

## Installation

Add `prompt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prompt, "~> 0.x.x"}
  ]
end
```

[Read the documentation](https://hexdocs.pm/prompt/Prompt.html)

## Basic Usage

### Ask the user for confirmation
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
