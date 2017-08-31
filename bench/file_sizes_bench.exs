defmodule FileSizesBench do
  use Benchfella

  setup_all do
    refs = {
      File.read!("bench/github_trending_js.html") |> Myhtmlex.open,
      File.read!("bench/w3c_html5.html") |> Myhtmlex.open,
      File.read!("bench/wikipedia_hyperlink.html") |> Myhtmlex.open
    }
    {:ok, refs}
  end

  bench "github_trending_js.html 341k" do
    {ref, _, _} = bench_context
    Myhtmlex.decode_tree(ref)
  end

  bench "w3c_html5.html 131k" do
    {_, ref, _} = bench_context
    Myhtmlex.decode_tree(ref)
  end

  bench "wikipedia_hyperlink.html 97k" do
    {_, _, ref} = bench_context
    Myhtmlex.decode_tree(ref)
  end

end

