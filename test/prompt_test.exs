defmodule PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "confirm" do
    test "handle confirm" do
      assert capture_io("y", fn ->
               result = Prompt.confirm("Send the email?")
               assert result == :yes
             end) =~ "Send the email? (Y/n): "
    end

    test "handle confirm - default" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :yes
             end) =~ "Send the email? (Y/n): "
    end

    test "handle confirm - default to no" do
      assert capture_io("\n", fn ->
               result = Prompt.confirm("Send the email?", default_answer: :no)
               assert result == :no
             end) =~ "Send the email? (y/N): "
    end

    test "handle confirm - no" do
      assert capture_io("n", fn ->
               result = Prompt.confirm("Send the email?", [])
               assert result == :no
             end) =~ "Send the email? (Y/n): "
    end

    test "handle confirm - unknown answer" do
      assert capture_io("asdf", fn ->
               Prompt.confirm("Send the email?", [])
             end) =~ "Send the email? (Y/n): "
    end

    test "handle confirm - mask output" do
      assert capture_io("y", fn ->
               result = Prompt.confirm("Send the email?", mask_line: true)
               assert result == :yes
             end) =~ "#######"
    end
  end

  describe "choice" do
    test "handle custom choices" do
      assert capture_io("y", fn ->
               result = Prompt.choice("Send the email?", yes: "y", no: "n")
               assert result == :yes
             end) =~ "Send the email? (Y/n): "
    end

    test "handle many custom choices" do
      assert capture_io("y", fn ->
               result = Prompt.choice("Send the email?", yes: "y", no: "n", cancel: "c")
               assert result == :yes
             end) =~ "Send the email? (Y/n/c): "
    end

    test "handle many custom choices - default" do
      assert capture_io("\n", fn ->
               result =
                 Prompt.choice("Send the email?", [yes: "y", no: "n", cancel: "c"],
                   default_answer: :cancel
                 )

               assert result == :cancel
             end) =~ "Send the email? (y/n/C): "
    end
  end

  describe "select" do
    test "returns selected option" do
      assert capture_io("1", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"])
               assert result == "t@t.com"
             end) =~ "Which email? [1-2]:"
    end

    test "requires choice from list" do
      assert capture_io("3", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) =~ "Enter a number from 1-2: "
    end

    test "requires valid number" do
      assert capture_io("one", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"])
             end) =~ "Enter a number from 1-2: "
    end

    test "allows list of tuples" do
      assert capture_io("1", fn ->
               result = Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}])
               assert result == "t"
             end) =~ "Which email? [1-2]:"
    end

    test "returns selected options(multi)" do
      assert capture_io("1 2", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
               assert result == ["t@t.com", "a@a.com"]
             end) =~ "Which email? [1-2]:"
    end

    test "allows list of tuples(multi)" do
      assert capture_io("1 2", fn ->
               result =
                 Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}], multi: true)

               assert result == ["t", "a"]
             end) =~ "Which email? [1-2]:"
    end

    test "returns selected options(multi) - requires integers" do
      assert capture_io("one", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
             end) =~ "Enter numbers from 1-2 seperated by spaces: "
    end

    test "returns selected options(multi) - requires choice" do
      assert capture_io("3", fn ->
               Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
             end) =~ "Enter numbers from 1-2 seperated by spaces: "
    end
  end

  describe "text" do
    test "returns input" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address")
               assert result == "t@t.com"
             end)
    end

    test "validates min length" do
      assert capture_io("t@", fn ->
               result = Prompt.text("email address", min: 3)
               assert result == :error_min
             end)
    end

    test "validates max length" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address", max: 3)
               assert result == :error_max
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
             end) =~ "#######"
    end

    test "shows list of text" do
      assert capture_io(fn ->
               assert Prompt.display(["hello", "world"]) == :ok
             end) =~ "world"
    end

    test "shows text on the right" do
      assert capture_io(fn ->
               assert Prompt.display("hello", position: :right) == :ok
             end) =~ "hello"
    end
  end

  describe "tables" do
    test "display simple table" do
      assert capture_io(fn ->
               Prompt.table([
                 ["Hello", "from", "the", "terminal!"],
                 ["this", "is", "another", "row"]
               ])
             end) =~
               "\e[39m+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n\e[0m\e[0m"
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
             end) =~
               "\e[39m+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n+-------+------+---------+-----------+\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n\e[0m\e[0m"
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
