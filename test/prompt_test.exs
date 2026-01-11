defmodule PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    Application.put_env(:prompt, :io, IO)
  end

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
      assert capture_io("\r", fn ->
               result = Prompt.select("Which email?", ["t@t.com", "a@a.com"])
               assert result == "t@t.com"
             end) =~ "Which email?"
    end

    test "allows list of tuples" do
      assert capture_io("\r", fn ->
               result = Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}])
               assert result == "t"
             end) =~ "Which email?"
    end

    # Figure out how best to test these
    # test "returns selected options(multi)" do
    #   assert capture_io("\t", fn ->
    #            result = Prompt.select("Which email?", ["t@t.com", "a@a.com"], multi: true)
    #            assert result == ["t@t.com", "a@a.com"]
    #          end) =~ "Which email? [1-2]:"
    # end
    #
    # test "allows list of tuples(multi)" do
    #   assert capture_io("\t \r", fn ->
    #            result =
    #              Prompt.select("Which email?", [{"t@t.com", "t"}, {"a@a.com", "a"}], multi: true)
    #
    #            assert result == ["t"]
    #          end) =~ "Which email?"
    # end
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

    test "validates min length - valid" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address", min: 3)
               assert result == "t@t.com"
             end)
    end

    test "validates max length" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address", max: 3)
               assert result == :error_max
             end)
    end

    test "validates max length - valid" do
      assert capture_io("t@t.com", fn ->
               result = Prompt.text("email address", max: 10)
               assert result == "t@t.com"
             end)
    end
  end

  # capture_io doesn't work work 'raw' shell mode
  # describe "password" do
  #   test "ask for hidden input" do
  #     assert capture_io("password\n", fn ->
  #              result = Prompt.password("Enter Password: ")
  #              assert result == "password"
  #            end)
  #   end
  # end

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
               "\e[39m+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n"
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
               "\e[39m+-------+------+---------+-----------+\n| Hello | from | the     | terminal! |\n+-------+------+---------+-----------+\n| this  | is   | another | row       |\n+-------+------+---------+-----------+\n"
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
