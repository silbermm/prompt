defmodule Prompt.IO.Color do
  @moduledoc false

  @typedoc "The colors allowed for text and background"
  @type t ::
          :black
          | :blue
          | :cyan
          | :green
          | :light_black
          | :light_blue
          | :light_cyan
          | :light_green
          | :light_magneta
          | :light_red
          | :light_white
          | :light_yellow
          | :magenta
          | :red
          | :white
          | :yellow

  def all() do
    [
      :black,
      :blue,
      :cyan,
      :green,
      :light_black,
      :light_blue,
      :light_cyan,
      :light_green,
      :light_magneta,
      :light_red,
      :light_white,
      :light_yellow,
      :magenta,
      :red,
      :white,
      :yellow
    ]
  end
end
