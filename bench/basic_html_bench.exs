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

  bench "decode with ref" do
    {_, ref} = bench_context
    Myhtmlex.decode_tree(ref)
  end

end

