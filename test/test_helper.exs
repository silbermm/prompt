# Colors are only emitted when ANSI is enabled, which Elixir decides from
# whether stdout is a TTY. Force it on so output is the same in a terminal,
# in CI, and under a pipe.
Application.put_env(:elixir, :ansi_enabled, true)

ExUnit.start()

Mox.defmock(Prompt.IO.Mock, for: Prompt.IO)
Application.put_env(:prompt, :io, Prompt.IO.Mock)
