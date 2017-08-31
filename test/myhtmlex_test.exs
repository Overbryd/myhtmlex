defmodule MyhtmlexTest do
  use ExUnit.Case
  doctest Myhtmlex

  test "builds a tree" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], []}
    ]} = Myhtmlex.decode("<html></html>")
  end

  test "attributes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:span, [{"id", "test"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<span id="test" class="foo garble"></span>')
  end

  test "single attributes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:button, [{"disabled", "disabled"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<button disabled class="foo garble"></span>')
  end

  test "text nodes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        "text node"
      ]}
    ]} = Myhtmlex.decode(~s'<body>text node</body>')
  end

  test "broken input" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:a, [{"<", "<"}], [" asdf"]}
      ]}
    ]} = Myhtmlex.decode(~s'<a <> asdf')
  end

  test "open" do
    ref = Myhtmlex.open(~s'<dif class="a"></div><div class="b"></div>')
    assert is_reference(ref)
  end

  test "open and decode_tree" do
    ref = Myhtmlex.open(~s'text node')
    assert is_reference(ref)
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        "text node"
      ]}
    ]} = Myhtmlex.decode_tree(ref)
  end

  test "namespaced tags" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {"svg:svg", [], [
          {"svg:path", [], []},
          {"svg:a", [], []}
        ]}
      ]}
    ]} = Myhtmlex.decode(~s'<svg><path></path><a></a></svg>')
  end

  test "custom namespaced tags" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {"esi:include", [], nil}
      ]}
    ]} = Myhtmlex.decode(~s'<esi:include />')
  end

  test "open this nasty github file (works fine in parse single, parse threaded hangs)" do
    html = File.read!("bench/github_trending_js.html")
    ref = Myhtmlex.open(html)
    assert is_reference(ref)
  end

end

