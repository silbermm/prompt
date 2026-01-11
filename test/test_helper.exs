ExUnit.start()

Mox.defmock(Prompt.IO.Mock, for: Prompt.IO)
Application.put_env(:prompt, :io, Prompt.IO.Mock)
