defmodule Myhtmlex do
  @moduledoc """
  A module to decode html into a tree structure.

  Based on [Alexander Borisov's myhtml](https://github.com/lexborisov/myhtml),
  this binding gains the properties of being html-spec compliant and very fast.

  ## Example

      iex> Myhtmlex.decode("<h1>Hello world</h1>")
      {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Hello world"]}]}]}

  Benchmark results on various file sizes on a 2,5Ghz Core i7:

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

  ## Thoughts

  I need to a fast html-parsing library in Erlang/Elixir.
  So falling back to c, and to myhtml especially, is a natural move.

  But Erlang interoperability is a tricky mine-field.
  This increase in parsing speed does not come for free.

  The current implementation can be considered a proof-of-concept.
  The myhtml code is called as a dirty-nif and executed **inside the Erlang-VM**.
  Thus completely giving up the safety of the Erlang-VM. I am not saying that myhtml is unsafe, but
  the slightest Segfault brings down the whole Erlang-VM.
  So, I consider this mode of operation unsafe, and **not recommended for production use**.

  The other option, that I have on my roadmap, is to call into a C-Node.
  A separate OS-process that receives calls from erlang and returns to the calling process.

  Another option is to call into a Port driver.
  A separate OS-process that communicates via stdin/stdout.

  So to recap, I want a **fast** and **safe** html-parsing library for Erlang/Elixir.

  Not quite there, yet.
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
  def decode(bin) do
    Myhtmlex.Decoder.decode(bin)
  end

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
        {:body, [], [{:comment, " a comment "}, {"unknown", [], nil}]}]}

  """
  @spec decode(String.t, format: [format_flag()]) :: tree()
  def decode(bin, format: flags) do
    Myhtmlex.Decoder.decode(bin, flags)
  end

  @doc """
  Returns a reference to an internally parsed myhtml_tree_t.
  """
  @spec open(String.t) :: reference()
  def open(bin) do
    Myhtmlex.Decoder.open(bin)
  end

  @doc """
  Returns a tree representation from the given reference. See `decode/1` for example output.
  """
  @spec decode_tree(reference()) :: tree()
  def decode_tree(ref) do
    Myhtmlex.Decoder.decode_tree(ref)
  end

  @doc """
  Returns a tree representation from the given reference. See `decode/2` for options and example output.
  """
  @spec decode_tree(reference(), format: [format_flag()]) :: tree()
  def decode_tree(ref, format: flags) do
    Myhtmlex.Decoder.decode_tree(ref, flags)
  end
end

