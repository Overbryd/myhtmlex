defmodule Myhtmlex.Decoder do
  @on_load { :init, 0 }

  app = Mix.Project.config[:app]

  def init do
    path = :filename.join(:code.priv_dir(unquote(app)), 'myhtmlex')
    :ok = :erlang.load_nif(path, 0)
  end

  @spec decode(bin :: String.t) :: {atom(), list(), list()}
  def decode(bin)
  def decode(_), do: exit(:nif_library_not_loaded)

  def decode(bin, flags)
  def decode(_, _), do: exit(:nif_library_not_loaded)

  def open(bin)
  def open(_), do: exit(:nif_library_not_loaded)

  def decode_tree(tree)
  def decode_tree(_), do: exit(:nif_library_not_loaded)

  def decode_tree(tree, flags)
  def decode_tree(_, _), do: exit(:nif_library_not_loaded)
end
