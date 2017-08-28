defmodule MyhtmlexTest do
  use ExUnit.Case
  doctest Myhtmlex

  test "builds a tree" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], []}
    ]} = Myhtmlex.decode("<html></html>")
  end

  test "attributes" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        {"span", [{"id", "test"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<span id="test" class="foo garble"></span>')
  end

  test "single attributes" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        {"button", [{"disabled", "disabled"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<button disabled class="foo garble"></span>')
  end

  test "text nodes" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        "text node"
      ]}
    ]} = Myhtmlex.decode(~s'<body>text node</body>')
  end

  test "broken input" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        {"a", [{"<", "<"}], [" asdf"]}
      ]}
    ]} = Myhtmlex.decode(~s'<a <> asdf')
  end

#   test "open" do
#     assert %Myhtmlex.Doc{} = doc = Myhtmlex.open(~s'<dif class="a"></div><div class="b"></div>')
#   end
end

