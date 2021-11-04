defprotocol Prompt.IO do
  @moduledoc false

  @doc "Display the IO"
  def display(data)

  @doc "Evaluate the IO"
  def evaluate(data)
end
