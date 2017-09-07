defmodule BasicHtmlBench do
  use Benchfella

  setup_all do
    html = File.read!("bench/w3c_html5.html")
    context = {html, Myhtmlex.open(html)}
    {:ok, context}
  end

  bench "decode" do
    {html, _} = bench_context
    Myhtmlex.decode(html)
  end

  bench "decode w/ html_atoms" do
    {html, _} = bench_context
    Myhtmlex.decode(html, format: [:html_atoms])
  end

  bench "decode w/ nil_self_closing" do
    {html, _} = bench_context
    Myhtmlex.decode(html, format: [:nil_self_closing])
  end

  bench "decode w/ html_atoms, nil_self_closing" do
    {html, _} = bench_context
    Myhtmlex.decode(html, format: [:html_atoms, :nil_self_closing])
  end

  bench "decode_tree" do
    {_, ref} = bench_context
    Myhtmlex.decode_tree(ref)
  end

  bench "decode_tree w/ html_atoms" do
    {_, ref} = bench_context
    Myhtmlex.decode_tree(ref, format: [:html_atoms])
  end

end

