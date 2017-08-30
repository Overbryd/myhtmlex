defmodule BasicHtmlBench do
  use Benchfella

  @html File.read!("bench/w3c_html5.html")

  setup_all do
    ref = Myhtmlex.open(@html)
    {:ok, ref}
  end

  bench "decode" do
    Myhtmlex.decode(@html)
  end

  bench "decode with ref" do
    ref = bench_context
    Myhtmlex.decode_tree(ref)
  end

  # bench "encode" do
  #   Mixoml.encode(@decoded)
  # end
end

