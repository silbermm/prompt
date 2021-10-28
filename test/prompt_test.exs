defmodule PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "confirm" do
    test "handle confirm" do
      assert capture_io("y", fn ->
               result = Prompt.confirm("Send the email?")
               assert result == :yes
             end) == "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m"
    end

    test "handle confirm - default" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :yes
             end) == "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m"
    end

    test "handle confirm - default to no" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", default_answer: :no)
               assert result == :no
             end) == "\e[0m\e[49m\e[39mSend the email? (y/N): \e[0m\e[0m"
    end

    test "handle confirm - no" do
      assert capture_io("n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :no
             end) == "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m"
    end

    test "handle confirm - unknown answer" do
      assert capture_io("asdf", fn ->
               Prompt.confirm("Send the email?", [])
             end) ==
               "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m"
    end

    test "handle confirm - mask output" do
      assert capture_io("y", fn ->
               result = Prompt.confirm("Send the email?", mask_line: true)
               assert result == :yes
             end) ==
               "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m\e[1A\e[2K\e[3m\e[92m#######\e[0m\n"
    end
  end

  describe "choice" do
    test "handle custom choices" do
      assert capture_io("y", fn ->
               result = Prompt.choice("Send the email?", yes: "y", no: "n")
               assert result == :yes
             end) == "\e[0m\e[49m\e[39mSend the email? (Y/n): \e[0m\e[0m"
    end

    test "handle many custom choices" do
      assert capture_io("y", fn ->
               result = Prompt.choice("Send the email?", yes: "y", no: "n", cancel: "c")
               assert result == :yes
             end) == "\e[0m\e[49m\e[39mSend the email? (Y/n/c): \e[0m\e[0m"
    end

    test "handle many custom choices - default" do
      assert capture_io("\n", fn ->
               result =
                 Prompt.choice("Send the email?", [yes: "y", no: "n", cancel: "c"],
                   default_answer: :cancel
                 )

               assert result == :cancel
             end) == "\e[0m\e[49m\e[39mSend the email? (y/n/C): \e[0m\e[0m"
    end
  end

  describe "select" do
    test "returns selected option" do
      assert capture_io("1", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"])
               assert result == "t@t.com"
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:"
    end

    test "requires choice from list" do
      assert capture_io("3", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:\e[39m\e[49m\e[1mEnter a number from 1-2: \e[0m"
    end

    test "requires valid number" do
      assert capture_io("one", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:\e[39m\e[49m\e[1mEnter a number from 1-2: \e[0m"
    end

    test "allows list of tuples" do
      assert capture_io("1", fn ->
               result = Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}])
               assert result == "t"
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:"
    end

    test "returns selected options(multi)" do
      assert capture_io("1 2", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
               assert result == ["t@t.com", "a@a.com"]
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:"
    end

    test "allows list of tuples(multi)" do
      assert capture_io("1 2", fn ->
               result =
                 Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}], multi: true)

               assert result == ["t", "a"]
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:"
    end

    test "returns selected options(multi) - requires integers" do
      assert capture_io("one", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:\e[39m\e[49m\e[1mEnter numbers from 1-2 seperated by spaces: \e[0m"
    end

    test "returns selected options(multi) - requires choice" do
      assert capture_io("3", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
             end) ==
               "\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[1] t@t.com\e[0m\e[0m\e[49m\e[39m\e[1m\n\e[1000D\e[2C[2] a@a.com\e[0m\n\n\e[1000D\e[49m\e[39mWhich email? [1-2]:\e[39m\e[49m\e[1mEnter numbers from 1-2 seperated by spaces: \e[0m"
    end
  end

  describe "text" do
    test "returns input" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address")
               assert result == "t@t.com"
             end)
    end
  end

  describe "password" do
    test "ask for hidden input" do
      assert capture_io("password", fn ->
               result = Prompt.password("Enter Password: ")
               assert result == "password"
             end)
    end
  end

  describe "display" do
    test "hides text on enter" do
      assert capture_io("\n", fn ->
               assert Prompt.display("password", mask_line: true) == :ok
             end) ==
               "\e[0m\e[49m\e[39mpassword\e[0m [Press Enter to continue]\e[0m\e[1A\e[2K\e[3m\e[92m#######\e[0m\n"
    end

    test "shows list of text" do
      assert capture_io(fn ->
               assert Prompt.display(["hello", "world"]) == :ok
             end) == "\e[0m\e[49m\e[39mhello\e[0m\n\e[0m\e[0m\e[49m\e[39mworld\e[0m\n\e[0m"
    end

    test "shows text on the right" do
      assert capture_io(fn ->
               assert Prompt.display("hello", position: :right) == :ok
             end) == "\e[10000C\e[5D\e[0m\e[49m\e[39mhello\e[0m\n\e[0m"
    end
  end

  describe "tables" do
    test "display simple table" do
      assert capture_io(fn ->
               Prompt.table([
                 ["Hello", "from", "the", "terminal!"],
                 ["this", "is", "another", "row"]
               ])
             end) ==
               "+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n"
    end

    test "display simple table with headers" do
      assert capture_io(fn ->
               Prompt.table(
                 [
                   ["Hello", "from", "the", "terminal!"],
                   ["this", "is", "another", "row"]
                 ],
                 header: true
               )
             end) ==
               "+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n+-------+------+---------+-----------+\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n"
    end

    test "return table data" do
      assert Prompt.table_data([
               ["Hello", "from", "the", "terminal!"],
               ["this", "is", "another", "row"]
             ]) ==
               [
                 [["+-------", "+------", "+---------", "+-----------"], "+", "\n"],
                 "",
                 [
                   "| Hello | from | the     | terminal! |\n",
                   "| this  | is   | another | row       |\n"
                 ],
                 [["+-------", "+------", "+---------", "+-----------"], "+", "\n"]
               ]
    end
  end
end
