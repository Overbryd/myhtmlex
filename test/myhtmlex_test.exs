defmodule MyhtmlexTest do
  use ExUnit.Case
  doctest Myhtmlex

  test "builds a tree, formatted like mochiweb by default" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        {"br", [], []}
      ]}
    ]} = Myhtmlex.decode("<br>")
  end

  test "builds a tree, html tags as atoms" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:br, [], []}
      ]}
    ]} = Myhtmlex.decode("<br>", format: [:html_atoms])
  end

  test "builds a tree, nil self closing" do
    assert {"html", [], [
      {"head", [], []},
      {"body", [], [
        {"br", [], nil},
        {"esi:include", [], nil}
      ]}
    ]} = Myhtmlex.decode("<br><esi:include />", format: [:nil_self_closing])
  end

  test "builds a tree, multiple format options" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:br, [], nil}
      ]}
    ]} = Myhtmlex.decode("<br>", format: [:html_atoms, :nil_self_closing])
  end

  test "attributes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:span, [{"id", "test"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<span id="test" class="foo garble"></span>', format: [:html_atoms])
  end

  test "single attributes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:button, [{"disabled", "disabled"}, {"class", "foo garble"}], []}
      ]}
    ]} = Myhtmlex.decode(~s'<button disabled class="foo garble"></span>', format: [:html_atoms])
  end

  test "text nodes" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        "text node"
      ]}
    ]} = Myhtmlex.decode(~s'<body>text node</body>', format: [:html_atoms])
  end

  test "broken input" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {:a, [{"<", "<"}], [" asdf"]}
      ]}
    ]} = Myhtmlex.decode(~s'<a <> asdf', format: [:html_atoms])
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
    ]} = Myhtmlex.decode_tree(ref, format: [:html_atoms])
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
    ]} = Myhtmlex.decode(~s'<svg><path></path><a></a></svg>', format: [:html_atoms])
  end

  test "custom namespaced tags" do
    assert {:html, [], [
      {:head, [], []},
      {:body, [], [
        {"esi:include", [], nil}
      ]}
    ]} = Myhtmlex.decode(~s'<esi:include />', format: [:html_atoms, :nil_self_closing])
  end

  test "open this nasty github file (works fine in parse single, parse threaded hangs)" do
    html = File.read!("bench/github_trending_js.html")
    ref = Myhtmlex.open(html)
    assert is_reference(ref)
  end

end

