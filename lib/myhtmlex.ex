defmodule Myhtmlex do
  @moduledoc """
  A module to decode html into a tree structure.

  Based on [Alexander Borisov's myhtml](https://github.com/lexborisov/myhtml),
  this binding gains the properties of being html-spec compliant and very fast.

  ## Example

      iex> Myhtmlex.decode("<h1>Hello world</h1>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Hello world"]}]}]}

  Benchmark results (Nif calling mode) on various file sizes on a 2,5Ghz Core i7:

      Settings:
        duration:      1.0 s

      ## FileSizesBench
      [15:28:42] 1/3: github_trending_js.html 341k
      [15:28:46] 2/3: w3c_html5.html 131k
      [15:28:48] 3/3: wikipedia_hyperlink.html 97k

      Finished in 7.52 seconds

      ## FileSizesBench
      benchmark name                iterations   average time
      wikipedia_hyperlink.html 97k        1000   1385.86 µs/op
      w3c_html5.html 131k                 1000   2179.30 µs/op
      github_trending_js.html 341k         500   5686.21 µs/op

  ## Configuration

  The module you are calling into is always `Myhtmlex` and depending on your application configuration,
  it chooses between the underlying implementations `Myhtmlex.Safe` (default) and `:myhtmlex_nif`.

  Erlang interoperability is a tricky mine-field.
  You can call into C directly using native implemented functions (Nif). But this comes with the risk,
  that if anything goes wrong within the C implementation, your whole VM will crash.
  No more supervisor cushions for here on, just violent crashes.

  That is why the default mode of operation keeps your VM safe and happy.
  If you need ultimate parsing speed, or you can simply tolerate VM-level crashes, read on.

  ### Call into C-Node (default)

  This is the default mode of operation.
  If your application cannot tolerate VM-level crashes, this option allows you to gain the best of both worlds.
  The added overhead is client/server communications, and a worker OS-process that runs next to your VM under VM supervision.

  You do not have to do anything to start the worker process, everything is taken care of within the library.
  If you are not running in distributed mode, your VM will automatically be assigned a `sname`.

  The worker OS-process stays alive as long as it is under VM-supervision. If your VM goes down, the OS-process will die by itself.
  If the worker OS-process dies for some reason, your VM stays unaffected and will attempt to restart it seamlessly.

  ### Call into Nif

  If your application is aiming for ultimate parsing speed, and in the worst case can tolerate VM-level crashes, you can call directly into the Nif.

  1. Require myhtmlex without runtime

      in your `mix.exs`

          def deps do
            [
              {:myhtmlex, ">= 0.0.0", runtime: false}
            ]
          end

  2. Configure the mode to `:myhtmlex_nif`

      e.g. in `config/config.exs`

          config :myhtmlex, mode: :myhtmlex_nif

  3. Bonus: You can [open up in-memory references to parsed trees](https://hexdocs.pm/myhtmlex/Myhtmlex.html#open/1), without parsing + mapping erlang terms in one go
  """

  @type tag() :: String.t | atom()
  @type attr() :: {String.t, String.t}
  @type attr_list() :: [] | [attr()]
  @type comment_node() :: {:comment, String.t}
  @type comment_node3() :: {:comment, [], String.t}
  @type tree() :: {tag(), attr_list(), tree()}
    | {tag(), attr_list(), nil}
    | comment_node()
    | comment_node3()
  @type format_flag() :: :html_atoms | :nil_self_closing | :comment_tuple3

  defp module() do
    Application.get_env(:myhtmlex, :mode, :myhtmlex_nif)
  end

  @doc """
  Returns a tree representation from the given html string.

  ## Examples

      iex> Myhtmlex.decode("<h1>Hello world</h1>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Hello world"]}]}]}

      iex> Myhtmlex.decode("<span class='hello'>Hi there</span>")
      {"html", [],
       [{"head", [], []},
        {"body", [], [{"span", [{"class", "hello"}], ["Hi there"]}]}]}

      iex> Myhtmlex.decode("<body><!-- a comment --!></body>")
      {"html", [], [{"head", [], []}, {"body", [], [comment: " a comment "]}]}

      iex> Myhtmlex.decode("<br>")
      {"html", [], [{"head", [], []}, {"body", [], [{"br", [], []}]}]}
  """
  @spec decode(String.t) :: tree()
  defdelegate decode(bin), to: :myhtmlex

  @doc """
  Returns a tree representation from the given html string.

  This variant allows you to pass in one or more of the following format flags:

  * `:html_atoms` uses atoms for known html tags (faster), binaries for everything else.
  * `:nil_self_closing` uses `nil` to designate self-closing tags and void elements.
      For example `<br>` is then being represented like `{"br", [], nil}`.
      See http://w3c.github.io/html-reference/syntax.html#void-elements for a full list of void elements.
  * `:comment_tuple3` uses 3-tuple elements for comments, instead of the default 2-tuple element.

  ## Examples

      iex> Myhtmlex.decode("<h1>Hello world</h1>", format: [:html_atoms])
      {:html, [], [{:head, [], []}, {:body, [], [{:h1, [], ["Hello world"]}]}]}

      iex> Myhtmlex.decode("<br>", format: [:nil_self_closing])
      {"html", [], [{"head", [], []}, {"body", [], [{"br", [], nil}]}]}

      iex> Myhtmlex.decode("<body><!-- a comment --!></body>", format: [:comment_tuple3])
      {"html", [], [{"head", [], []}, {"body", [], [{:comment, [], " a comment "}]}]}

      iex> html = "<body><!-- a comment --!><unknown /></body>"
      iex> Myhtmlex.decode(html, format: [:html_atoms, :nil_self_closing, :comment_tuple3])
      {:html, [],
       [{:head, [], []},
        {:body, [], [{:comment, [], " a comment "}, {"unknown", [], nil}]}]}

  """
  @spec decode(String.t, format: [format_flag()]) :: tree()
  def decode(bin, format: flags) do
    module().decode(bin, flags)
  end

  @doc """
  Returns a reference to an internally parsed myhtml_tree_t. (Nif only!)
  """
  @spec open(String.t) :: reference()
  defdelegate open(bin), to: :myhtmlex

  @doc """
  Returns a tree representation from the given reference. See `decode/1` for example output.  (Nif only!)
  """
  @spec decode_tree(reference()) :: tree()
  defdelegate decode_tree(ref), to: :myhtmlex

  @doc """
  Returns a tree representation from the given reference. See `decode/2` for options and example output. (Nif only!)
  """
  @spec decode_tree(reference(), format: [format_flag()]) :: tree()
  defdelegate decode_tree(ref, format_opt), to: :myhtmlex
end
