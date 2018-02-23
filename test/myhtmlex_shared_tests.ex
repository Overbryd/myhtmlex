defmodule MyhtmlexSharedTests do
  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :module)
    quote do
      use ExUnit.Case
      doctest Myhtmlex

      setup_all(_) do
        Application.put_env(:myhtmlex, :mode, unquote(module))
        :ok
      end

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

      test "html comments" do
        assert {:html, [], [
          {:head, [], []},
          {:body, [], [
            comment: " a comment "
          ]}
        ]} = Myhtmlex.decode(~s'<body><!-- a comment --></body>', format: [:html_atoms])
      end
    end # quote
  end # defmacro __using__

end

