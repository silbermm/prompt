defmodule Prompt.Example.Command1 do
  @moduledoc false
  use Prompt.Command

  defstruct [:limit, :print]

  @impl true
  def init(opts) do
    %__MODULE__{limit: opts.limit, print: opts.print}
  end

  @impl true
  def process(%__MODULE__{} = cmd) do
    display("cmd1 ran - limit: #{cmd.limit}!", color: :red)
  end
end

defmodule Prompt.Example.Command2 do
  @moduledoc false
  use Prompt.Command

  @impl true
  def process(cmd) do
    cmd
  end
end

defmodule Prompt.Example.FallbackCommand do
  @moduledoc false
  use Prompt.Command

  @impl true
  def process(cmd) do
    display("fallback command")
  end
end

defmodule Prompt.Example do
  @moduledoc false

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
