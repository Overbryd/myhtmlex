defmodule BasicHtmlBench do
  use Benchfella

  @html File.read!("bench/w3c_html5.html")
  # @decoded Exoml.decode(@html)

  bench "decode" do
    Myhtmlex.decode(@html)
  end

#   bench "encode" do
#     Mixoml.encode(@decoded)
#   end
end

