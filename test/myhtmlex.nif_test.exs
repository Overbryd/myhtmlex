defmodule Myhtmlex.NifTest do
  use MyhtmlexSharedTests, module: :myhtmlex_nif

  test "parse a larger file (131K)" do
    html = File.read!("bench/github_trending_js.html")
    ref = Myhtmlex.open(html)
    assert is_reference(ref)
    assert is_tuple(Myhtmlex.decode_tree(ref))
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
end
