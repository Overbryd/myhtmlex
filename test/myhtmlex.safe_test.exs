defmodule Myhtmlex.SafeTest do
  use MyhtmlexSharedTests, module: Myhtmlex.Safe

  test "doesn't segfault when <!----> is encountered" do
    assert {"html", _attrs, _children} = Myhtmlex.decode("<div> <!----> </div>")
  end
end

