defmodule Prompt.Example.Command1 do
  use Prompt.Command

  defstruct [:limit, :print]

  @impl true
  def init(opts) do
    %__MODULE__{limit: opts.limit, print: opts.print}
  end

  @impl true
  def process(%__MODULE__{} = cmd) do
    display("cmd1 ran - limit: #{cmd.limit}!", color: :red)
    0
  end
end

defmodule Prompt.Example.Command2 do
  use Prompt.Command

  @impl true
  def process(cmd) do
    cmd
  end
end

defmodule Prompt.Example.FallbackCommand do
  use Prompt.Command

  @impl true
  def process(cmd) do
    IO.inspect(cmd)
    display("fallback command")
  end
end

defmodule Prompt.Example do
  @moduledoc """
  Example usage of Prompt

    --help    Show this help message
    --version Show the version of the app
  """

  use Prompt.Router, otp_app: :prompt

  command :cmd1, Prompt.Example.Command1 do
    arg(:limit, :integer, default: 6)
    arg(:print, :boolean)
  end

  command :cmd2, Prompt.Example.Command2 do
    arg(:whatever, :string, [])
  end

  command "", Prompt.Example.FallbackCommand do
    arg(:blah, :boolean)
    arg(:cmd1, :boolean)
    arg(:limit, :integer)
  end
end
