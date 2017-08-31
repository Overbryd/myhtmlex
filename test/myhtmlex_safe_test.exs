defmodule MyhtmlexSafeTest do
  use ExUnit.Case

  test "it works" do
    tree = Myhtmlex.Safe.decode("foo")
    assert {"html", [], [{"head", [], []}, {"body", [], ["foo"]}]} = tree
  end

end

