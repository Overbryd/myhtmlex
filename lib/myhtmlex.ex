defmodule Myhtmlex do
  def decode(bin) do
    Myhtmlex.Decoder.decode(bin)
  end

  def decode(bin, format: flags) do
    Myhtmlex.Decoder.decode(bin, flags)
  end

  def open(bin) do
    Myhtmlex.Decoder.open(bin)
  end

  def decode_tree(tree) do
    Myhtmlex.Decoder.decode_tree(tree)
  end

  def decode_tree(tree, format: flags) do
    Myhtmlex.Decoder.decode_tree(tree, flags)
  end
end
