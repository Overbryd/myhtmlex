defmodule CnodeFileSizesBench do
  use Benchfella

  setup_all do
    Nodex.Distributed.up
    {:ok, _pid} = Nodex.Cnode.start_link(%{exec_path: "priv/myhtml_worker"}, name: Myhtmlex.Safe.Cnode)
    contents = {
      File.read!("bench/github_trending_js.html"),
      File.read!("bench/w3c_html5.html"),
      File.read!("bench/wikipedia_hyperlink.html")
    }
    {:ok, contents}
  end

  bench "github_trending_js.html 341k" do
    {ref, _, _} = bench_context
    Myhtmlex.Safe.decode(ref)
  end

  bench "w3c_html5.html 131k" do
    {_, ref, _} = bench_context
    Myhtmlex.Safe.decode(ref)
  end

  bench "wikipedia_hyperlink.html 97k" do
    {_, _, ref} = bench_context
    Myhtmlex.Safe.decode(ref)
  end

end

